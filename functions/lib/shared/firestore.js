"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.fetchTeams = fetchTeams;
exports.fetchTeam = fetchTeam;
exports.chunkedBatchWrite = chunkedBatchWrite;
/**
 * Firestore utility functions shared across all domain modules.
 */
const admin_1 = require("./admin");
/** Maximum number of IDs per Firestore `in` query. */
const FIRESTORE_IN_LIMIT = 30;
/** Maximum write operations per Firestore batch. */
const BATCH_SIZE_LIMIT = 450;
/**
 * Fetches team documents by ID array.
 * Splits into chunks of 30 to respect Firestore `in` query limits.
 * @param teamIds Array of team document IDs to fetch.
 * @returns Array of Firestore DocumentSnapshots for found teams.
 */
async function fetchTeams(teamIds) {
    if (!teamIds.length)
        return [];
    const docs = [];
    for (let i = 0; i < teamIds.length; i += FIRESTORE_IN_LIMIT) {
        const chunk = teamIds.slice(i, i + FIRESTORE_IN_LIMIT);
        const snap = await admin_1.db.collection("teams").where("id", "in", chunk).get();
        snap.docs.forEach((d) => docs.push(d));
    }
    return docs;
}
/**
 * Fetches a team document as a typed object.
 * Returns null if the document does not exist.
 * @param teamId The team document ID.
 */
async function fetchTeam(teamId) {
    const snap = await admin_1.db.collection("teams").doc(teamId).get();
    if (!snap.exists)
        return null;
    return { ...snap.data(), id: snap.id };
}
/**
 * Executes an array of batch write operations in chunks of 450.
 * Required because Firestore batches are capped at 500 operations.
 * @param ops Array of batch operations (set or update).
 */
async function chunkedBatchWrite(ops) {
    if (!ops.length)
        return;
    for (let i = 0; i < ops.length; i += BATCH_SIZE_LIMIT) {
        const chunk = ops.slice(i, i + BATCH_SIZE_LIMIT);
        const batch = admin_1.db.batch();
        for (const op of chunk) {
            if (op.type === "set") {
                batch.set(op.ref, op.data, op.options ?? {});
            }
            else {
                batch.update(op.ref, op.data);
            }
        }
        await batch.commit();
    }
}
