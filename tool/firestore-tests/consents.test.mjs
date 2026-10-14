import {before, after, beforeEach, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, setDoc, deleteDoc, serverTimestamp, Timestamp} from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-kumee',
    firestore: {host: '127.0.0.1', port: 8080, rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8')},
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => env?.cleanup());

const db = (uid) => env.authenticatedContext(uid, {email_verified: true}).firestore();
const consent = (legalVersion, extra = {}) => ({schemaVersion: 1, legalVersion, acceptedAt: serverTimestamp(), ...extra});
async function staff(uid, role) {
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'admins', uid), {role}));
}

test('members record, read, raise and delete their own consent', async () => {
  const ref = doc(db('amina'), 'consents', 'amina');
  await assertSucceeds(setDoc(ref, consent(1)));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(setDoc(ref, consent(2)));
  await assertFails(setDoc(ref, consent(1)));
  await assertSucceeds(deleteDoc(ref));
});

test('consent must be well formed and stamped by the server', async () => {
  const ref = doc(db('amina'), 'consents', 'amina');
  for (const bad of [
    consent(0), consent('1'), consent(1, {extra: true}), {schemaVersion: 1, legalVersion: 1},
    consent(1, {schemaVersion: 2}), consent(1, {acceptedAt: Timestamp.fromMillis(0)}),
  ]) {
    await assertFails(setDoc(ref, bad));
  }
});

test('nobody else can read or write a member consent, except admins reading', async () => {
  await assertSucceeds(setDoc(doc(db('amina'), 'consents', 'amina'), consent(1)));
  await assertFails(getDoc(doc(db('yusuf'), 'consents', 'amina')));
  await assertFails(setDoc(doc(db('yusuf'), 'consents', 'amina'), consent(2)));
  await assertFails(deleteDoc(doc(db('yusuf'), 'consents', 'amina')));
  await staff('mod', 'moderator');
  await assertFails(getDoc(doc(db('mod'), 'consents', 'amina')));
  await staff('boss', 'admin');
  await assertSucceeds(getDoc(doc(db('boss'), 'consents', 'amina')));
  await assertFails(setDoc(doc(db('boss'), 'consents', 'amina'), consent(2)));
});
