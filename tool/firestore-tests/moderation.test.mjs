import {before, after, beforeEach, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, addDoc, collection, query, where, writeBatch, serverTimestamp, Timestamp} from 'firebase/firestore';

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
const birth = Timestamp.fromMillis(Date.UTC(2001, 0, 15));
const db = (uid) => env.authenticatedContext(uid, {email_verified: true}).firestore();

function answers(gender) {
  return {name: gender === 'female' ? 'Hodan' : 'Ahmed', gender, nationality: 'SO', residenceCountry: 'GB', city: 'London', ethnicity: 'somali', ethnicityOther: '', profession: 'nurse', professionOther: '', education: 'bachelors', practice: 'active', marriageTimeline: 'withinYear', relocation: 'open', maritalStatus: 'neverMarried', about: 'Seeking a respectful marriage.'};
}
async function seedMember(uid, gender, {verification = 'pending', listed = true} = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'profiles', uid), {schemaVersion: 2, ...answers(gender), onboardingComplete: true, createdAt: created, updatedAt: created});
    await setDoc(doc(d, 'privateAccounts', uid), {schemaVersion: 2, adultConfirmed: true, birthDate: birth, phoneCountry: 'GB', phoneNumber: '+447700900123', createdAt: created, updatedAt: created});
    await setDoc(doc(d, 'profilePhotos', uid), {schemaVersion: 1, photoIds: [id(1)], updatedAt: created});
    await setDoc(doc(d, 'profilePhotoFiles', uid, 'items', id(1)), {data: 'photo'});
    if (verification) {
      await setDoc(doc(d, 'verifications', uid), {schemaVersion: 1, status: verification, selfieId: id(9), gender, submittedAt: created});
      await setDoc(doc(d, 'verificationSelfieFiles', uid, 'items', id(9)), {data: 'selfie'});
    }
    if (listed) await setDoc(doc(d, 'publicProfiles', uid), {schemaVersion: 1, ...answers(gender), birthYearMonth: 200101, photoIds: [id(1)], photosBlurred: false, verified: false, updatedAt: created});
  });
}
async function seedStaff(uid, role, reviewGender) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'admins', uid), {role, ...(reviewGender ? {reviewGender} : {})});
  });
}
const decision = (status, uid) => ({status, reviewNote: 'Clear match', reviewedAt: serverTimestamp(), reviewedBy: uid});

test('only the console can create staff; staff read their own role', async () => {
  await seedStaff('boss', 'admin');
  await seedStaff('rev', 'reviewer');
  await assertFails(setDoc(doc(db('her'), 'admins', 'her'), {role: 'admin'}));
  await assertFails(setDoc(doc(db('boss'), 'admins', 'new'), {role: 'admin'}));
  await assertSucceeds(getDoc(doc(db('rev'), 'admins', 'rev')));
  await assertFails(getDoc(doc(db('rev'), 'admins', 'boss')));
  await assertSucceeds(getDoc(doc(db('boss'), 'admins', 'rev')));
  await assertSucceeds(getDocs(collection(db('boss'), 'admins')));
  await assertFails(getDocs(collection(db('rev'), 'admins')));
});

test('reviewers see and decide only their gender; members and others cannot decide', async () => {
  await seedMember('her', 'female');
  await seedMember('him', 'male');
  await seedStaff('womenRev', 'reviewer', 'female');
  await seedStaff('anyRev', 'reviewer');
  await seedStaff('mod', 'moderator');
  const w = db('womenRev');
  await assertSucceeds(getDoc(doc(w, 'verificationSelfieFiles', 'her', 'items', id(9))));
  await assertSucceeds(getDoc(doc(w, 'profilePhotoFiles', 'her', 'items', id(1))));
  await assertSucceeds(getDoc(doc(w, 'profiles', 'her')));
  await assertFails(getDoc(doc(w, 'verificationSelfieFiles', 'him', 'items', id(9))));
  await assertFails(getDoc(doc(w, 'profiles', 'him')));
  await assertSucceeds(getDocs(query(collection(w, 'verifications'), where('status', '==', 'pending'), where('gender', '==', 'female'))));
  await assertFails(getDocs(query(collection(w, 'verifications'), where('status', '==', 'pending'))));
  await assertFails(getDoc(doc(w, 'privateAccounts', 'her')));
  await assertFails(updateDoc(doc(w, 'verifications', 'him'), decision('verified', 'womenRev')));
  await assertFails(updateDoc(doc(w, 'verifications', 'her'), decision('verified', 'someoneElse')));
  await assertFails(updateDoc(doc(w, 'verifications', 'her'), {...decision('verified', 'womenRev'), selfieId: id(8)}));
  await assertFails(updateDoc(doc(w, 'verifications', 'her'), decision('approved', 'womenRev')));
  await assertSucceeds(updateDoc(doc(w, 'verifications', 'her'), decision('verified', 'womenRev')));
  await assertSucceeds(updateDoc(doc(db('anyRev'), 'verifications', 'him'), decision('rejected', 'anyRev')));
  await assertSucceeds(getDocs(query(collection(db('anyRev'), 'verifications'), where('status', '==', 'pending'))));
  await assertFails(updateDoc(doc(db('mod'), 'verifications', 'her'), decision('rejected', 'mod')));
  await assertFails(getDoc(doc(db('mod'), 'verificationSelfieFiles', 'her', 'items', id(9))));
  await assertFails(updateDoc(doc(db('her'), 'verifications', 'her'), decision('verified', 'her')));
  await assertFails(getDoc(doc(db('him'), 'verificationSelfieFiles', 'her', 'items', id(9))));
});

test('admins read private details; moderators search members but not private data', async () => {
  await seedMember('her', 'female');
  await seedStaff('boss', 'admin');
  await seedStaff('mod', 'moderator');
  await assertSucceeds(getDoc(doc(db('boss'), 'privateAccounts', 'her')));
  await assertFails(getDoc(doc(db('mod'), 'privateAccounts', 'her')));
  await assertSucceeds(getDocs(collection(db('mod'), 'profiles')));
  await assertSucceeds(getDocs(collection(db('mod'), 'publicProfiles')));
  await assertFails(getDocs(collection(db('her'), 'publicProfiles')));
  await assertFails(getDocs(collection(db('her'), 'profiles')));
  await assertSucceeds(getDoc(doc(db('mod'), 'profilePhotoFiles', 'her', 'items', id(1))));
});

test('moderators suspend and reactivate; suspended members leave Discover', async () => {
  await seedMember('her', 'female');
  await seedMember('him', 'male');
  await seedStaff('mod', 'moderator');
  await seedStaff('rev', 'reviewer');
  const status = (s, by) => ({status: s, reason: 'Repeated harassment reports', updatedAt: serverTimestamp(), updatedBy: by});
  await assertFails(setDoc(doc(db('rev'), 'accountStatus', 'him'), status('suspended', 'rev')));
  await assertFails(setDoc(doc(db('him'), 'accountStatus', 'him'), status('active', 'him')));
  await assertFails(setDoc(doc(db('mod'), 'accountStatus', 'him'), status('banned', 'mod')));
  await assertFails(setDoc(doc(db('mod'), 'accountStatus', 'him'), status('suspended', 'other')));
  const mod = db('mod');
  const suspend = writeBatch(mod);
  suspend.set(doc(mod, 'accountStatus', 'him'), status('suspended', 'mod'));
  suspend.delete(doc(mod, 'publicProfiles', 'him'));
  await assertSucceeds(suspend.commit());
  await assertSucceeds(getDoc(doc(db('him'), 'accountStatus', 'him')));
  await assertFails(getDoc(doc(db('her'), 'accountStatus', 'him')));
  // A suspended member cannot list themselves or see anyone.
  await assertFails(setDoc(doc(db('him'), 'publicProfiles', 'him'), {schemaVersion: 1, ...answers('male'), birthYearMonth: 200101, photoIds: [id(1)], photosBlurred: false, verified: false, updatedAt: serverTimestamp()}));
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'publicProfiles', 'him'), {schemaVersion: 1, ...answers('male'), birthYearMonth: 200101, photoIds: [id(1)], photosBlurred: false, verified: false, updatedAt: created});
  });
  await assertFails(getDoc(doc(db('him'), 'publicProfiles', 'her')));
  await assertSucceeds(setDoc(doc(mod, 'accountStatus', 'him'), status('active', 'mod')));
  await assertSucceeds(getDoc(doc(db('him'), 'publicProfiles', 'her')));
  await assertFails(deleteDoc(doc(mod, 'accountStatus', 'him')));
});

test('members report profiles they can see; only moderators read and resolve reports', async () => {
  await seedMember('her', 'female');
  await seedMember('him', 'male');
  await seedStaff('mod', 'moderator');
  const report = (extra = {}) => ({reporterUid: 'him', reportedUid: 'her', reason: 'scam', note: 'Asked for money', status: 'open', createdAt: serverTimestamp(), ...extra});
  const him = db('him');
  for (const bad of [{reporterUid: 'other'}, {reportedUid: 'him'}, {reason: 'boring'}, {status: 'resolved'}, {note: 'x'.repeat(501)}, {extra: true}]) {
    await assertFails(addDoc(collection(him, 'reports'), report(bad)));
  }
  const ref = await assertSucceeds(addDoc(collection(him, 'reports'), report()));
  await assertFails(getDoc(ref));
  await assertFails(getDocs(collection(him, 'reports')));
  const mod = db('mod');
  await assertSucceeds(getDocs(query(collection(mod, 'reports'), where('status', '==', 'open'))));
  const resolve = (extra = {}) => ({status: 'resolved', resolution: 'Warned member', resolvedAt: serverTimestamp(), resolvedBy: 'mod', ...extra});
  await assertFails(updateDoc(doc(mod, 'reports', ref.id), resolve({reason: 'other'})));
  await assertFails(updateDoc(doc(mod, 'reports', ref.id), resolve({resolvedBy: 'someone'})));
  await assertSucceeds(updateDoc(doc(mod, 'reports', ref.id), resolve()));
  await assertFails(updateDoc(doc(him, 'reports', ref.id), resolve({resolvedBy: 'him'})));
});

test('blocks hide members from each other in both directions', async () => {
  await seedMember('her', 'female');
  await seedMember('him', 'male');
  const her = db('her');
  const block = {blocker: 'her', blocked: 'him', blockedName: 'Ahmed', createdAt: serverTimestamp()};
  await assertFails(setDoc(doc(her, 'blocks', 'him_her'), block));
  await assertFails(setDoc(doc(db('him'), 'blocks', 'her_him'), block));
  await assertFails(setDoc(doc(her, 'blocks', 'her_her'), {...block, blocked: 'her'}));
  await assertSucceeds(getDoc(doc(db('him'), 'publicProfiles', 'her')));
  await assertSucceeds(setDoc(doc(her, 'blocks', 'her_him'), block));
  await assertFails(getDoc(doc(db('him'), 'publicProfiles', 'her')));
  await assertFails(getDoc(doc(her, 'publicProfiles', 'him')));
  await assertFails(getDoc(doc(db('him'), 'profilePhotoFiles', 'her', 'items', id(1))));
  await assertSucceeds(getDocs(query(collection(her, 'blocks'), where('blocker', '==', 'her'))));
  await assertSucceeds(getDocs(query(collection(db('him'), 'blocks'), where('blocked', '==', 'him'))));
  await assertFails(getDocs(collection(db('him'), 'blocks')));
  await assertFails(deleteDoc(doc(db('him'), 'blocks', 'her_him')));
  await assertSucceeds(deleteDoc(doc(her, 'blocks', 'her_him')));
  await assertSucceeds(getDoc(doc(db('him'), 'publicProfiles', 'her')));
});

test('staff can remove listings; members cannot remove others', async () => {
  await seedMember('her', 'female');
  await seedStaff('rev', 'reviewer', 'female');
  await assertFails(deleteDoc(doc(db('him'), 'publicProfiles', 'her')));
  await assertSucceeds(deleteDoc(doc(db('rev'), 'publicProfiles', 'her')));
});
