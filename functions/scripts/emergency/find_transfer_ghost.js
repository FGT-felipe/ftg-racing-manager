/**
 * find_transfer_ghost.js
 *
 * Recovery script for T-028: finds drivers that were transferred by the
 * resolver but may be in a broken state (wrong role, missing fields, etc.).
 *
 * What it does:
 *  1. Lists all human-managed teams (managerId != "")
 *  2. For each team, shows all drivers assigned to it (by teamId)
 *  3. Flags drivers with missing/wrong role, or leftover bid fields
 *  4. Shows recent "Transfer Bid Won" news from team office
 *
 * Usage:
 *   node find_transfer_ghost.js               ← report only
 *   node find_transfer_ghost.js --fix          ← fix role on ghost drivers (sets role="reserve")
 */

const fs = require("fs");
const path = require("path");

const configPath = path.join(
    process.env.USERPROFILE || process.env.HOME,
    ".config", "configstore", "firebase-tools.json"
);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_ghost.json");
fs.writeFileSync(adcPath, JSON.stringify({
    type: "authorized_user",
    client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
    client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
    refresh_token: config.tokens.refresh_token,
}, null, 2));
process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

const FIX_MODE = process.argv.includes("--fix");

async function main() {
    console.log(FIX_MODE
        ? "🔧 FIX MODE — will set role=reserve on ghost drivers\n"
        : "🔍 REPORT MODE — no writes. Pass --fix to repair.\n"
    );

    // ── 1. Find human teams ───────────────────────────────────────────────────
    const teamsSnap = await db.collection("teams").where("isBot", "==", false).get();
    console.log(`Found ${teamsSnap.size} human team(s).\n`);

    for (const tDoc of teamsSnap.docs) {
        const team = tDoc.data();
        console.log(`${"═".repeat(60)}`);
        console.log(`TEAM: ${team.name} (${tDoc.id})`);
        console.log(`Manager: ${team.managerId || "(none)"} | Budget: $${(team.budget || 0).toLocaleString()}`);
        console.log(`${"─".repeat(60)}`);

        // ── 2. All drivers assigned to this team ──────────────────────────────
        const driversSnap = await db.collection("drivers")
            .where("teamId", "==", tDoc.id)
            .get();

        if (driversSnap.empty) {
            console.log("  No drivers found for this team.\n");
        } else {
            console.log(`  Drivers assigned (${driversSnap.size}):`);
            for (const dDoc of driversSnap.docs) {
                const d = dDoc.data();
                const role = d.role || "⚠️  MISSING ROLE";
                const hasBidFields = d.currentHighestBid > 0 || d.highestBidderTeamId;
                const pendingNeg = d.pendingNegotiation ? "⚠️  pendingNegotiation=true" : "";
                const ghost = !d.role ? " ← GHOST (no role)" : "";

                console.log(`\n    [${dDoc.id}] ${d.name} (${d.gender || "?"}, ${d.age})`);
                console.log(`      role: ${role}${ghost}`);
                console.log(`      isTransferListed: ${d.isTransferListed}`);
                console.log(`      currentHighestBid: ${d.currentHighestBid || 0}`);
                console.log(`      contractYearsRemaining: ${d.contractYearsRemaining}`);
                console.log(`      salary: $${(d.salary || 0).toLocaleString()}`);
                if (hasBidFields) console.log(`      ⚠️  leftover bid fields present`);
                if (pendingNeg) console.log(`      ${pendingNeg}`);

                // Fix ghost driver
                if (FIX_MODE && !d.role) {
                    await dDoc.ref.update({ role: "reserve" });
                    console.log(`      ✅ Fixed: role set to "reserve"`);
                }
            }
        }

        // ── 3. Recent Transfer news (no orderBy — avoids composite index) ───────
        const newsSnap = await db.collection("teams").doc(tDoc.id)
            .collection("news")
            .where("type", "==", "TRANSFER_WON")
            .limit(10)
            .get();

        if (!newsSnap.empty) {
            console.log(`\n  Recent "Transfer Bid Won" news (${newsSnap.size}):`);
            for (const n of newsSnap.docs) {
                const nd = n.data();
                const ts = nd.timestamp?.toDate?.()?.toISOString() || "unknown time";
                console.log(`    [${ts}] ${nd.message}`);
            }
        }

        console.log();
    }

    // ── 4. Scan for drivers with bid fields still set (stuck in limbo) ───────
    console.log(`${"═".repeat(60)}`);
    console.log("DRIVERS STUCK IN TRANSFER LIMBO (bid fields still set)");
    console.log(`${"─".repeat(60)}`);

    const limboDrSnap = await db.collection("drivers")
        .where("currentHighestBid", ">", 0)
        .get();

    if (limboDrSnap.empty) {
        console.log("  None found — no active bids in the system.");
    } else {
        for (const d of limboDrSnap.docs) {
            const dr = d.data();
            console.log(`  [${d.id}] ${dr.name} | teamId: ${dr.teamId || "(none)"} | bid: $${dr.currentHighestBid?.toLocaleString()} | bidder: ${dr.highestBidderTeamId} | listed: ${dr.isTransferListed}`);
        }
    }
    console.log();

    // ── 5. Drivers with no team that were recently delisted ──────────────────
    console.log(`${"═".repeat(60)}`);
    console.log("FREE AGENT DRIVERS (teamId empty — may be deleted transfer target)");
    console.log(`${"─".repeat(60)}`);

    const freeAgentSnap = await db.collection("drivers")
        .where("teamId", "==", "")
        .get();

    if (freeAgentSnap.empty) {
        console.log("  No free agent drivers.");
    } else {
        for (const d of freeAgentSnap.docs) {
            const dr = d.data();
            console.log(`  [${d.id}] ${dr.name} (${dr.gender}, ${dr.age}) | isTransferListed: ${dr.isTransferListed} | bid: ${dr.currentHighestBid || 0}`);
        }
    }
    console.log();

    console.log("Done.");
}

main()
    .catch(e => { console.error("❌ Fatal:", e); })
    .finally(() => {
        try { fs.unlinkSync(adcPath); } catch (_) {}
        process.exit(0);
    });
