const test = require("node:test");
const assert = require("node:assert/strict");
const invite = require("../lib/inviteCode");

test("alphabet excludes look-alike characters", () => {
    for (const ch of ["0", "O", "1", "I", "L"]) {
        assert.equal(invite.INVITE_CODE_ALPHABET.includes(ch), false, ch);
    }
});

test("codes stay compatible with old clients (8 x [A-Z0-9])", () => {
    for (let i = 0; i < 500; i++) {
        const code = invite.generateInviteCode();
        assert.match(code, /^[A-Z0-9]{8}$/);
        assert.doesNotMatch(code, /[01OIL]/);
    }
});

test("unique generation retries on collisions", async () => {
    let calls = 0;
    const code = await invite.generateUniqueInviteCode(async () => ++calls < 3);
    assert.equal(calls, 3);
    assert.match(code, /^[A-Z0-9]{8}$/);
    await assert.rejects(invite.generateUniqueInviteCode(async () => true, 2));
});

test("normalizeInviteCode accepts what the app accepts", () => {
    assert.equal(invite.normalizeInviteCode("abcd-2345"), "ABCD2345");
    assert.equal(invite.normalizeInviteCode(" ABCD 2345 "), "ABCD2345");
    assert.equal(invite.normalizeInviteCode("ABCD–2345"), "ABCD2345");
    assert.equal(invite.normalizeInviteCode("OLD01IL9"), "OLD01IL9");
    assert.equal(invite.normalizeInviteCode("ABC"), null);
    assert.equal(invite.normalizeInviteCode("ABCD23456"), null);
    assert.equal(invite.normalizeInviteCode("ABCD234!"), null);
    assert.equal(invite.normalizeInviteCode(12345678), null);
    assert.equal(invite.normalizeInviteCode(undefined), null);
});
