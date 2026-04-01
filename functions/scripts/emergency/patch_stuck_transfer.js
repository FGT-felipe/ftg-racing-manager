/**
 * patch_stuck_transfer.js
 *
 * Emergency recovery for transfers stuck because transferListedAt was saved
 * as an ISO string instead of a Firestore Timestamp, making the resolver's
 * Timestamp-based query unable to find them.
 *
 * What it does:
 *  1. Scans all drivers with isTransferListed=true
 *  2. Identifies those where transferListedAt is a STRING (the bug)
 *  3. If the listing has expired (> LISTING_HOURS ago) and has a winning bid:
 *     - Assigns driver to winning team (teamId)
 *     - Deducts bid amount from buyer's budget
 *     - Credits seller's budget (if driver had a team)
 *     - Sends office news to both teams
 *     - Clears listing/bid fields
 *  4. If expired but no bid: delists driver cleanly
 *  5. If NOT yet expired: fixes the field type (string → Timestamp) in place
 *     so the resolver can find it when it does expire
 *
 * Usage:
 *   node patch_stuck_transfer.js            ← dry-run
 *   node patch_stuck_transfer.js --execute  ← apply
 */

const fs = require("fs");
const path = require("path");

const configPath = path.join(
    process.env.USERPROFILE || process.env.HOME,
    ".config", "configstore", "firebase-tools.json"
);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_patch_transfer.json");
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

const DRY_RUN = !process.argv.includes("--execute");
const LISTING_HOURS = 24;
const LISTING_MS = LISTING_HOURS * 60 * 60 * 1000;

async function addNews(teamId, title, message, type) {
    await db.collection("teams").doc(teamId).collection("news").add({
        title,
        message,
        type,
        teamId,
        isRead: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
}

async function main() {
    console.log(DRY_RUN
        ? "🔍 DRY-RUN — no writes. Pass --execute to apply.\n"
        : "🚨 EXECUTE MODE — writing to Firestore.\n"
    );

    const snap = await db.collection("drivers")
        .where("isTransferListed", "==", true)
        .get();

    if (snap.empty) {
        console.log("No transfer-listed drivers found.");
        cleanup(); return;
    }

    const now = Date.now();
    let fixedCount = 0;
    let processedCount = 0;

    for (const dDoc of snap.docs) {
        const d = dDoc.data();
        const raw = d.transferListedAt;

        // Only handle string-type dates (the bug)
        if (!raw || typeof raw !== "string") {
            console.log(`[${dDoc.id}] ${d.name} — transferListedAt is a Timestamp, skipping (resolver handles it).`);
            continue;
        }

        const listedAt = new Date(raw).getTime();
        const ageMs = now - listedAt;
        const expired = ageMs >= LISTING_MS;
        const highestBid = d.currentHighestBid || 0;
        const buyerTeamId = d.highestBidderTeamId || null;
        const sellerTeamId = d.teamId || null;

        console.log(`\n[${dDoc.id}] ${d.name}`);
        console.log(`  listedAt: ${raw} (${Math.round(ageMs / 3600000)}h ago)`);
        console.log(`  expired: ${expired} | bid: $${highestBid.toLocaleString()} | buyer: ${buyerTeamId || "(none)"}`);

        if (!expired) {
            // Just fix the field type — convert string → Timestamp
            console.log(`  → Not expired yet. Fixing field type string → Timestamp.`);
            if (!DRY_RUN) {
                await dDoc.ref.update({
                    transferListedAt: admin.firestore.Timestamp.fromDate(new Date(raw)),
                });
                console.log(`  ✅ transferListedAt converted to Timestamp.`);
            }
            fixedCount++;
            continue;
        }

        // Expired listing — resolve it
        if (highestBid > 0 && buyerTeamId) {
            // ── Transfer to winning bidder ────────────────────────────────────
            console.log(`  → SOLD to ${buyerTeamId} for $${highestBid.toLocaleString()}`);

            if (!DRY_RUN) {
                const batch = db.batch();

                // Update driver
                batch.update(dDoc.ref, {
                    isTransferListed: false,
                    transferListedAt: admin.firestore.FieldValue.delete(),
                    currentHighestBid: admin.firestore.FieldValue.delete(),
                    highestBidderTeamId: admin.firestore.FieldValue.delete(),
                    teamId: buyerTeamId,
                    salary: Math.max(d.salary || 10_000, 10_000),
                    contractYearsRemaining: 1,
                });

                // Deduct from buyer
                batch.update(db.collection("teams").doc(buyerTeamId), {
                    budget: admin.firestore.FieldValue.increment(-highestBid),
                });

                // Credit seller (if had a team)
                if (sellerTeamId) {
                    batch.update(db.collection("teams").doc(sellerTeamId), {
                        budget: admin.firestore.FieldValue.increment(highestBid),
                    });
                }

                await batch.commit();

                // News
                await addNews(buyerTeamId,
                    "Transfer Completed",
                    `${d.name} has joined your team after winning the bid for $${highestBid.toLocaleString()}. Contract: 1 year.`,
                    "TRANSFER_WON"
                );
                if (sellerTeamId) {
                    await addNews(sellerTeamId,
                        "Driver Sold",
                        `${d.name} was sold to another team for $${highestBid.toLocaleString()}.`,
                        "TRANSFER_SOLD"
                    );
                }

                console.log(`  ✅ Driver transferred. Buyer -$${highestBid.toLocaleString()}. Seller +$${highestBid.toLocaleString()}.`);
            }
            processedCount++;

        } else {
            // ── No bid — delist ───────────────────────────────────────────────
            console.log(`  → No bid. Delisting.`);
            if (!DRY_RUN) {
                await dDoc.ref.update({
                    isTransferListed: false,
                    transferListedAt: admin.firestore.FieldValue.delete(),
                    currentHighestBid: admin.firestore.FieldValue.delete(),
                    highestBidderTeamId: admin.firestore.FieldValue.delete(),
                });
                if (sellerTeamId) {
                    await addNews(sellerTeamId,
                        "Driver Unsold",
                        `Nobody bid on ${d.name}. They remain in your team.`,
                        "TRANSFER_UNSOLD"
                    );
                }
                console.log(`  ✅ Driver delisted.`);
            }
            processedCount++;
        }
    }

    console.log(`\n${"─".repeat(50)}`);
    console.log(`Summary:`);
    console.log(`  Field type fixes (not expired): ${fixedCount}`);
    console.log(`  Transfers resolved:             ${processedCount}`);
    if (DRY_RUN) {
        console.log("\n🔍 Dry-run complete. Run with --execute to apply.");
    }

    cleanup();
}

function cleanup() {
    try { fs.unlinkSync(adcPath); } catch (_) {}
    process.exit(0);
}

main().catch(e => { console.error("❌ Fatal:", e); cleanup(); });
