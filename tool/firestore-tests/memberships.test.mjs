import {before, after, beforeEach, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, getDocs, setDoc, deleteDoc, collection, writeBatch, serverTimestamp, Timestamp} from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-kumee',
    firestore: {host: '127.0.0.1', port: 8080, rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8')},
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => env?.cleanup());

const id = (n) => `Photo${String(n).padStart(15, '0')}`;
const created = Timestamp.fromMillis(Date.UTC(2026, 0, 1));
const db = (uid) => env.authenticatedContext(uid, {email_verified: true}).firestore();
const future = (days) => Timestamp.fromMillis(Date.now() + days * 86400000);
async function admin(fn) { await env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore())); }
async function staff(uid, role) { await admin((d) => setDoc(doc(d, 'admins', uid), {role})); }
const grant = (by, plan = 'premium', extra = {}) => ({plan, expiresAt: future(30), grantedBy: by, source: 'admin', updatedAt: serverTimestamp(), ...extra});

function answers(gender) {
  return {name: gender === 'female' ? 'Hodan' : 'Ahmed', gender, nationality: 'SO', residenceCountry: 'GB', city: 'London', ethnicity: 'somali', ethnicityOther: '', profession: 'nurse', professionOther: '', education: 'bachelors', practice: 'active', marriageTimeline: 'withinYear', relocation: 'open', maritalStatus: 'neverMarried', about: 'Seeking a respectful marriage.'};
}

test('only administrators grant memberships, and only valid ones', async () => {
  await staff('boss', 'admin');
  await staff('mod', 'moderator');
  const ref = (viewer) => doc(db(viewer), 'memberships', 'her');
  await assertFails(setDoc(ref('her'), grant('her')));
  await assertFails(setDoc(ref('mod'), grant('mod')));
  for (const bad of [
    {plan: 'gold'}, {plan: 'free'}, {expiresAt: Timestamp.fromMillis(Date.now() - 1000)},
    {grantedBy: 'someone'}, {source: 'play'}, {extra: 1}, {updatedAt: created},
  ]) {
    await assertFails(setDoc(ref('boss'), grant('boss', 'premium', bad)));
  }
  await assertSucceeds(setDoc(ref('boss'), grant('boss', 'vip')));
  await assertSucceeds(getDocs(collection(db('boss'), 'memberships')));
  await assertFails(getDocs(collection(db('mod'), 'memberships')));
  await assertSucceeds(deleteDoc(ref('boss')));
});

test('members read only their own membership; staff may read any', async () => {
  await staff('rev', 'reviewer');
  await admin((d) => setDoc(doc(d, 'memberships', 'her'), {plan: 'premium', expiresAt: future(30), grantedBy: 'boss', source: 'admin', updatedAt: created}));
  await assertSucceeds(getDoc(doc(db('her'), 'memberships', 'her')));
  await assertFails(getDoc(doc(db('him'), 'memberships', 'her')));
  await assertSucceeds(getDoc(doc(db('rev'), 'memberships', 'her')));
});

async function mutualLikes() {
  await admin(async (d) => {
    for (const [uid, gender] of [['her', 'female'], ['him', 'male']]) {
      await setDoc(doc(d, 'publicProfiles', uid), {schemaVersion: 1, ...answers(gender), birthYearMonth: 200101, photoIds: [id(1)], photosBlurred: false, verified: false, updatedAt: created});
    }
    await setDoc(doc(d, 'likes', 'him_her'), {from: 'him', to: 'her', createdAt: created});
  });
}
function likeBackAndMatch(uid = 'her') {
  const d = db(uid);
  const batch = writeBatch(d);
  batch.set(doc(d, 'likes', 'her_him'), {from: 'her', to: 'him', createdAt: serverTimestamp()});
  batch.set(doc(d, 'matches', 'her_him'), {users: ['her', 'him'], createdAt: serverTimestamp()});
  return batch.commit();
}

test('two free members cannot match; the like alone is kept', async () => {
  await mutualLikes();
  await assertFails(likeBackAndMatch());
  await assertSucceeds(setDoc(doc(db('her'), 'likes', 'her_him'), {from: 'her', to: 'him', createdAt: serverTimestamp()}));
});

test('either member having Premium or VIP lets the match form', async () => {
  await mutualLikes();
  await admin((d) => setDoc(doc(d, 'memberships', 'him'), {plan: 'premium', expiresAt: future(30), grantedBy: 'boss', source: 'admin', updatedAt: created}));
  await assertSucceeds(likeBackAndMatch());
});

test('an expired plan no longer counts', async () => {
  await mutualLikes();
  await admin((d) => setDoc(doc(d, 'memberships', 'him'), {plan: 'vip', expiresAt: Timestamp.fromMillis(Date.now() - 60000), grantedBy: 'boss', source: 'admin', updatedAt: created}));
  await assertFails(likeBackAndMatch());
});

test('only a current VIP may carry the VIP flag on the listing', async () => {
  await admin(async (d) => {
    await setDoc(doc(d, 'profiles', 'her'), {schemaVersion: 2, ...answers('female'), onboardingComplete: true, createdAt: created, updatedAt: created});
    await setDoc(doc(d, 'privateAccounts', 'her'), {schemaVersion: 2, adultConfirmed: true, birthDate: Timestamp.fromMillis(Date.UTC(2001, 0, 15)), phoneCountry: 'GB', phoneNumber: '+447700900123', createdAt: created, updatedAt: created});
    await setDoc(doc(d, 'profilePhotos', 'her'), {schemaVersion: 1, photoIds: [id(1)], updatedAt: created});
  });
  const listing = (extra) => ({schemaVersion: 1, ...answers('female'), birthYearMonth: 200101, photoIds: [id(1)], photosBlurred: false, verified: false, updatedAt: serverTimestamp(), ...extra});
  const ref = doc(db('her'), 'publicProfiles', 'her');
  await assertFails(setDoc(ref, listing({vip: true})));
  await assertSucceeds(setDoc(ref, listing({vip: false})));
  await admin((d) => setDoc(doc(d, 'memberships', 'her'), {plan: 'vip', expiresAt: future(30), grantedBy: 'boss', source: 'admin', updatedAt: created}));
  await assertSucceeds(setDoc(ref, listing({vip: true})));
  await assertFails(setDoc(ref, listing({vip: false})));
});
