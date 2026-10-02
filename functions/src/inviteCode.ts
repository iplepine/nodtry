import {randomInt} from "crypto";

// Easy-to-read alphabet: no 0/O, 1/I/L. Codes stay 8 upper-case alphanumerics
// so old app builds (which validate `^[A-Z0-9]{8}$`) still accept them.
export const INVITE_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
export const INVITE_CODE_LENGTH = 8;

/** Every code, old or new: 8 upper-case letters/digits (old codes may use 0/O/1/I/L). */
export const INVITE_CODE_PATTERN = /^[A-Z0-9]{8}$/;

/**
 * A typed or pasted code as the app normalises it (upper-cased, spaces and
 * dashes removed), or null when it is not a code at all.
 */
export function normalizeInviteCode(value: unknown): string | null {
    if (typeof value !== "string" || value.length > 64) return null;
    const code = value.replace(/[\s\-‐‑‒–—―−_]/g, "").toUpperCase();
    return INVITE_CODE_PATTERN.test(code) ? code : null;
}

export function generateInviteCode(nextInt: (max: number) => number = randomInt): string {
    let code = "";
    for (let i = 0; i < INVITE_CODE_LENGTH; i++) {
        code += INVITE_CODE_ALPHABET[nextInt(INVITE_CODE_ALPHABET.length)];
    }
    return code;
}

/**
 * Generates a code that `isTaken` reports as free. Throws after `attempts`
 * collisions (31^8 ≈ 8.5e11 codes, so this is effectively unreachable).
 */
export async function generateUniqueInviteCode(
    isTaken: (code: string) => Promise<boolean>,
    attempts = 8,
): Promise<string> {
    for (let i = 0; i < attempts; i++) {
        const code = generateInviteCode();
        if (!(await isTaken(code))) return code;
    }
    throw new Error("Could not generate a unique invite code");
}
