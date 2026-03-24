/**
 * Generic utility functions with no Firebase dependencies.
 */

/**
 * Returns a promise that resolves after the given number of milliseconds.
 * Used to stagger league processing and avoid Firestore write bursts.
 * @param ms Milliseconds to wait.
 */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
