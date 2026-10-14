import {before, after, beforeEach, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, getDocs, setDoc, deleteDoc, collection, query, where, writeBatch, runTransaction, serverTimestamp, Timestamp} from 'firebase/firestore';

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

function answers(gender) {
  return {name: gender === 'female' ? 'Hodan' : 'Ahmed', gender, nationality: 'SO', residenceCountry: 'GB', city: 'London', ethnicity: 'somali', ethnicityOther: '', profession: 'nurse', professionOther: '', education: 'bachelors', practice: 'active', marriageTimeline: 'withinYear', relocation: 'open', maritalStatus: 'neverMarried', about: 'Seeking a respectful marriage.'};
}
async function seed(uid, gender, {blurred = false} = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const d = ctx.firestore();
    await setDoc(doc(d, 'publicProfiles', uid), {schemaVersion: 1, ...answers(gender), birthYearMonth: 200101, photoIds: [id(1)], photosBlurred: blurred, verified: false, updatedAt: created});
    await setDoc(doc(d, 'profilePhotoFiles', uid, 'items', id(1)), {data: 'photo'});
  });
}
const like = (from, to) => ({from, to, createdAt: serverTimestamp()});
const matchData = (a, b) => ({users: [a, b].sort(), createdAt: serverTimestamp()});
const likeDoc = (viewer, from, to) => doc(db(viewer), 'likes', `${from}_${to}`);
// One member with an active Premium plan lets a match form (DEC-023).
async function premium(uid, plan = 'premium', days = 30) {
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'memberships', uid), {plan, expiresAt: Timestamp.fromMillis(Date.now() + days * 86400000), grantedBy: 'boss', source: 'admin', updatedAt: created}));
}

test('members like listed members of the opposite gender only', async () => {
  await seed('her', 'female');
  await seed('him', 'male');
  await seed('sis', 'female');
  await assertSucceeds(setDoc(likeDoc('him', 'him', 'her'), like('him', 'her')));
  await assertFails(setDoc(likeDoc('her', 'her', 'sis'), like('her', 'sis')));
  await assertFails(setDoc(likeDoc('her', 'him', 'her'), like('him', 'her')));
  await assertFails(setDoc(likeDoc('him', 'him', 'nobody'), like('him', 'nobody')));
  await assertFails(setDoc(likeDoc('him', 'him', 'sis'), like('him', 'her')));
  await assertFails(setDoc(likeDoc('him', 'him', 'sis'), {...like('him', 'sis'), note: 'hi'}));
  await assertFails(setDoc(likeDoc('him', 'him', 'sis'), {...like('him', 'sis'), createdAt: created}));
});

test('blocked members cannot like each other', async () => {
  await seed('her', 'female');
  await seed('him', 'male');
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'blocks', 'her_him'), {blocker: 'her', blocked: 'him', blockedName: 'Ahmed', createdAt: created}));
  await assertFails(setDoc(likeDoc('him', 'him', 'her'), like('him', 'her')));
});

test('only the two members read, list and remove a like', async () => {
  await seed('her', 'female');
  await seed('him', 'male');
  await seed('bro', 'male');
  await assertSucceeds(setDoc(likeDoc('him', 'him', 'her'), like('him', 'her')));
  await assertSucceeds(getDoc(likeDoc('her', 'him', 'her')));
  await assertFails(getDoc(likeDoc('bro', 'him', 'her')));
  await assertSucceeds(getDocs(query(collection(db('her'), 'likes'), where('to', '==', 'her'))));
  await assertSucceeds(getDocs(query(collection(db('him'), 'likes'), where('from', '==', 'him'))));
  await assertFails(getDocs(query(collection(db('bro'), 'likes'), where('to', '==', 'her'))));
  await assertFails(deleteDoc(likeDoc('bro', 'him', 'her')));
  await assertSucceeds(deleteDoc(likeDoc('her', 'him', 'her')));
  // Removing a like that does not exist is harmless, e.g. in a block batch.
  await assertSucceeds(deleteDoc(likeDoc('her', 'her', 'him')));
});

test('a match needs both likes, written together or before', async () => {
  await seed('her', 'female');
  await seed('him', 'male');
  await premium('him');
  await assertSucceeds(setDoc(likeDoc('him', 'him', 'her'), like('him', 'her')));
  // One like is not enough.
  await assertFails(setDoc(doc(db('him'), 'matches', 'her_him'), matchData('her', 'him')));
  // Her like and the match in one transaction.
  const herDb = db('her');
  await assertSucceeds(runTransaction(herDb, async (tx) => {
    const reverse = await tx.get(doc(herDb, 'likes', 'him_her'));
    tx.set(doc(herDb, 'likes', 'her_him'), like('her', 'him'));
    if (reverse.exists()) tx.set(doc(herDb, 'matches', 'her_him'), matchData('her', 'him'));
  }));
  await assertSucceeds(getDoc(doc(db('him'), 'matches', 'her_him')));
  await assertSucceeds(getDocs(query(collection(db('him'), 'matches'), where('users', 'array-contains', 'him'))));
  await assertFails(setDoc(doc(db('him'), 'matches', 'her_him'), matchData('her', 'him')));
});

test('match ids and contents must be exact; outsiders cannot match or read', async () => {
  await seed('her', 'female');
  await seed('him', 'male');
  await premium('him');
  await seed('bro', 'male');
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'likes', 'her_him'), {from: 'her', to: 'him', createdAt: created});
    await setDoc(doc(ctx.firestore(), 'likes', 'him_her'), {from: 'him', to: 'her', createdAt: created});
  });
  await assertFails(setDoc(doc(db('him'), 'matches', 'him_her'), {users: ['him', 'her'], createdAt: serverTimestamp()}));
  await assertFails(setDoc(doc(db('him'), 'matches', 'her_him'), {...matchData('her', 'him'), extra: 1}));
  await assertFails(setDoc(doc(db('bro'), 'matches', 'her_him'), matchData('her', 'him')));
  await assertSucceeds(setDoc(doc(db('him'), 'matches', 'her_him'), matchData('her', 'him')));
  await assertFails(getDoc(doc(db('bro'), 'matches', 'her_him')));
  await assertFails(deleteDoc(doc(db('bro'), 'matches', 'her_him')));
});

test('unmatching removes the match and both likes in one write', async () => {
  await seed('her', 'female');
  await seed('him', 'male');
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'likes', 'her_him'), {from: 'her', to: 'him', createdAt: created});
    await setDoc(doc(ctx.firestore(), 'likes', 'him_her'), {from: 'him', to: 'her', createdAt: created});
    await setDoc(doc(ctx.firestore(), 'matches', 'her_him'), {users: ['her', 'him'], createdAt: created});
  });
  const herDb = db('her');
  const batch = writeBatch(herDb);
  batch.delete(doc(herDb, 'matches', 'her_him'));
  batch.delete(doc(herDb, 'likes', 'her_him'));
  batch.delete(doc(herDb, 'likes', 'him_her'));
  await assertSucceeds(batch.commit());
});

test('a match shows blurred photos to the other member', async () => {
  await seed('her', 'female', {blurred: true});
  await seed('him', 'male');
  const photo = doc(db('him'), 'profilePhotoFiles', 'her', 'items', id(1));
  await assertFails(getDoc(photo));
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'matches', 'her_him'), {users: ['her', 'him'], createdAt: created}));
  await assertSucceeds(getDoc(photo));
});
