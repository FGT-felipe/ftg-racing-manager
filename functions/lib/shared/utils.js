"use strict";
/**
 * Generic utility functions with no Firebase dependencies.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.sleep = sleep;
/**
 * Returns a promise that resolves after the given number of milliseconds.
 * Used to stagger league processing and avoid Firestore write bursts.
 * @param ms Milliseconds to wait.
 */
function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
