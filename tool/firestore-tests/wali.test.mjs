import {before, after, beforeEach, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, query, where, writeBatch, serverTimestamp, Timestamp} from 'firebase/firestore';

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
const CODE = 'ABCD2345';

function answers(gender) {
  return {name: gender === 'female' ? 'Hodan' : 'Ahmed', gender, nationality: 'SO', residenceCountry: 'GB', city: 'London', ethnicity: 'somali', ethnicityOther: '', profession: 'nurse', professionOther: '', education: 'bachelors', practice: 'active', marriageTimeline: 'withinYear', relocation: 'open', maritalStatus: 'neverMarried', about: 'Seeking a respectful marriage.'};
}
async function seed(uid, gender) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'profiles', uid), {schemaVersion: 2, ...answers(gender), onboardingComplete: true, createdAt: created, updatedAt: created});
    await setDoc(doc(d, 'publicProfiles', uid), {schemaVersion: 1, ...answers(gender), birthYearMonth: 200101, photoIds: [id(1)], photosBlurred: false, verified: false, updatedAt: created});
  });
}
async function admin(fn) { await env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore())); }
const invite = (memberUid, extra = {}) => ({memberUid, memberName: 'Hodan', createdAt: serverTimestamp(), ...extra});

async function link(waliDb, waliUid, {name = 'Abdi', code = CODE} = {}) {
  const batch = writeBatch(waliDb);
  batch.set(doc(waliDb, 'guardians', waliUid), {name, createdAt: serverTimestamp()});
  batch.set(doc(waliDb, 'walis', 'her'), {waliUid, waliName: name, memberName: 'Hodan', inviteCode: code, linkedAt: serverTimestamp()});
  batch.delete(doc(waliDb, 'waliInvites', code));
  return batch.commit();
}
function candidate(gender) {
  const a = answers(gender);
  return {name: a.name, birthYearMonth: 200101, city: a.city, residenceCountry: a.residenceCountry, profession: a.profession, professionOther: a.professionOther, education: a.education, practice: a.practice, maritalStatus: a.maritalStatus, about: a.about, verified: false};
}
const request = (extra = {}) => ({memberUid: 'her', otherUid: 'him', waliUid: 'wali', status: 'pending', candidate: candidate('male'), createdAt: serverTimestamp(), ...extra});

test('a member invites with a well formed code carrying her own name', async () => {
  await seed('her', 'female');
  const her = db('her');
  await assertFails(setDoc(doc(her, 'waliInvites', 'abcd2345'), invite('her')));
  await assertFails(setDoc(doc(her, 'waliInvites', 'ABCD1234'), invite('her')));
  await assertFails(setDoc(doc(her, 'waliInvites', CODE), invite('her', {memberName: 'Someone'})));
  await assertFails(setDoc(doc(db('him'), 'waliInvites', CODE), invite('her')));
  await assertSucceeds(setDoc(doc(her, 'waliInvites', CODE), invite('her')));
  await assertSucceeds(getDocs(query(collection(her, 'waliInvites'), where('memberUid', '==', 'her'))));
  await assertFails(getDocs(query(collection(db('him'), 'waliInvites'), where('memberUid', '==', 'her'))));
});

test('a guardian links with a valid invite, using it up', async () => {
  await seed('her', 'female');
  await assertSucceeds(setDoc(doc(db('her'), 'waliInvites', CODE), invite('her')));
  const wali = db('wali');
  await assertSucceeds(getDoc(doc(wali, 'waliInvites', CODE)));
  await assertSucceeds(link(wali, 'wali'));
  await assertSucceeds(getDoc(doc(wali, 'walis', 'her')));
  await assertSucceeds(getDoc(doc(db('her'), 'walis', 'her')));
  await assertFails(getDoc(doc(db('him'), 'walis', 'her')));
  await assertSucceeds(getDocs(query(collection(wali, 'walis'), where('waliUid', '==', 'wali'))));
  // The code cannot be used again, and a second guardian cannot take over.
  await assertFails(link(db('other'), 'other'));
  await assertFails(setDoc(doc(db('her'), 'waliInvites', 'WXYZ6789'), invite('her')));
});

test('linking fails without an invite, with an expired one, or as yourself', async () => {
  await seed('her', 'female');
  await assertFails(link(db('wali'), 'wali'));
  await admin((d) => setDoc(doc(d, 'waliInvites', CODE), {memberUid: 'her', memberName: 'Hodan', createdAt: Timestamp.fromMillis(Date.now() - 8 * 86400000)}));
  await assertFails(link(db('wali'), 'wali'));
  await admin((d) => setDoc(doc(d, 'waliInvites', CODE), {memberUid: 'her', memberName: 'Hodan', createdAt: Timestamp.now()}));
  await assertFails(link(db('her'), 'her'));
  // The invite must be deleted in the same write.
  const wali = db('wali');
  const batch = writeBatch(wali);
  batch.set(doc(wali, 'guardians', 'wali'), {name: 'Abdi', createdAt: serverTimestamp()});
  batch.set(doc(wali, 'walis', 'her'), {waliUid: 'wali', waliName: 'Abdi', memberName: 'Hodan', inviteCode: CODE, linkedAt: serverTimestamp()});
  await assertFails(batch.commit());
});

test('members with a profile cannot become guardians', async () => {
  await seed('him', 'male');
  await assertFails(setDoc(doc(db('him'), 'guardians', 'him'), {name: 'Ahmed', createdAt: serverTimestamp()}));
  await assertSucceeds(setDoc(doc(db('wali'), 'guardians', 'wali'), {name: 'Abdi', createdAt: serverTimestamp()}));
});

async function linkedAndMatched() {
  await seed('her', 'female');
  await seed('him', 'male');
  await admin(async (d) => {
    await setDoc(doc(d, 'guardians', 'wali'), {name: 'Abdi', createdAt: created});
    await setDoc(doc(d, 'walis', 'her'), {waliUid: 'wali', waliName: 'Abdi', memberName: 'Hodan', inviteCode: CODE, linkedAt: created});
    await setDoc(doc(d, 'matches', 'her_him'), {users: ['her', 'him'], createdAt: created});
  });
}

test('match requests copy the listing exactly and need a match and a guardian', async () => {
  await linkedAndMatched();
  const her = db('her');
  const ref = doc(her, 'waliRequests', 'her_him');
  await assertFails(setDoc(ref, request({candidate: {...candidate('male'), name: 'Someone'}})));
  await assertFails(setDoc(ref, request({waliUid: 'other'})));
  await assertFails(setDoc(ref, request({status: 'approved'})));
  await assertFails(setDoc(doc(db('him'), 'waliRequests', 'her_him'), request()));
  await assertSucceeds(setDoc(ref, request()));
  // Readable by both members and the guardian, nobody else.
  await assertSucceeds(getDoc(doc(db('him'), 'waliRequests', 'her_him')));
  await assertSucceeds(getDoc(doc(db('wali'), 'waliRequests', 'her_him')));
  await assertFails(getDoc(doc(db('stranger'), 'waliRequests', 'her_him')));
  await assertSucceeds(getDocs(query(collection(db('wali'), 'waliRequests'), where('waliUid', '==', 'wali'))));
  await assertSucceeds(getDocs(query(collection(db('him'), 'waliRequests'), where('otherUid', '==', 'him'))));
});

test('without a match no request can be made', async () => {
  await linkedAndMatched();
  await admin((d) => deleteDoc(doc(d, 'matches', 'her_him')));
  await assertFails(setDoc(doc(db('her'), 'waliRequests', 'her_him'), request()));
});

test('only the current guardian decides', async () => {
  await linkedAndMatched();
  await assertSucceeds(setDoc(doc(db('her'), 'waliRequests', 'her_him'), request()));
  const decision = (status) => ({status, decidedAt: serverTimestamp()});
  await assertFails(updateDoc(doc(db('her'), 'waliRequests', 'her_him'), decision('approved')));
  await assertFails(updateDoc(doc(db('him'), 'waliRequests', 'her_him'), decision('approved')));
  await assertFails(updateDoc(doc(db('wali'), 'waliRequests', 'her_him'), decision('maybe')));
  await assertFails(updateDoc(doc(db('wali'), 'waliRequests', 'her_him'), {...decision('approved'), waliUid: 'x'}));
  await assertSucceeds(updateDoc(doc(db('wali'), 'waliRequests', 'her_him'), decision('approved')));
  // After the member removes him, he can no longer decide.
  await assertSucceeds(deleteDoc(doc(db('her'), 'walis', 'her')));
  await assertFails(updateDoc(doc(db('wali'), 'waliRequests', 'her_him'), decision('declined')));
});

test('either member removes requests; the guardian can step down', async () => {
  await linkedAndMatched();
  await assertSucceeds(setDoc(doc(db('her'), 'waliRequests', 'her_him'), request()));
  await assertFails(deleteDoc(doc(db('wali'), 'waliRequests', 'her_him')));
  await assertSucceeds(deleteDoc(doc(db('him'), 'waliRequests', 'her_him')));
  await assertFails(deleteDoc(doc(db('stranger'), 'walis', 'her')));
  await assertSucceeds(deleteDoc(doc(db('wali'), 'walis', 'her')));
});
