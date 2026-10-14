// Isolated REST contract check; does not verify the Flutter native SDK/device.
import assert from 'node:assert/strict';
const base = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const email = `kumee-${Date.now()}@example.test`;
const password = 'abcdef'; // Disposable emulator-only fixture, never a real credential.
async function request(action, body) {
  const response = await fetch(`${base}/accounts:${action}?key=emulator-only`, {
    method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body),
  });
  return { ok: response.ok, data: await response.json() };
}
let token;
try {
  const created = await request('signUp', { email, password, returnSecureToken: true });
  assert.equal(created.ok, true, 'six-character registration');
  token = created.data.idToken;
  assert.equal((await request('signUp', { email, password, returnSecureToken: true })).ok, false, 'duplicate rejected');
  assert.equal((await request('signInWithPassword', { email, password: 'incorrect', returnSecureToken: true })).ok, false, 'wrong password rejected');
  const login = await request('signInWithPassword', { email, password, returnSecureToken: true });
  assert.equal(login.ok, true, 'sign-in succeeds');
  assert.equal(login.data.localId, created.data.localId, 'same identity');
  assert.equal((await request('sendOobCode', {requestType: 'PASSWORD_RESET', email})).ok, true, 'reset requested');
  const codesResponse = await fetch('http://127.0.0.1:9099/emulator/v1/projects/demo-kumee/oobCodes');
  assert.equal(codesResponse.ok, true);
  const codes = await codesResponse.json();
  const code = codes.oobCodes.find((item) => item.email === email && item.requestType === 'PASSWORD_RESET');
  assert.ok(code, 'emulator reset code exists');
  const newPassword = 'reset-password-fixture';
  assert.equal((await request('resetPassword', {oobCode: code.oobCode, newPassword})).ok, true, 'reset completed');
  assert.equal((await request('resetPassword', {oobCode: code.oobCode, newPassword})).ok, false, 'code cannot be reused');
  assert.equal((await request('signInWithPassword', {email, password, returnSecureToken: true})).ok, false, 'old password rejected');
  const afterReset = await request('signInWithPassword', {email, password: newPassword, returnSecureToken: true});
  assert.equal(afterReset.ok, true, 'new password accepted');
  token = afterReset.data.idToken;
  console.log('PASS: emulator registration/sign-in and reset request, completion, one-time code, old/new password checks.');
} finally {
  if (token) assert.equal((await request('delete', { idToken: token })).ok, true, 'fixture cleanup');
}
