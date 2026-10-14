import {before, after, beforeEach, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, getDocs, setDoc, deleteDoc, collection, query, where, orderBy, writeBatch, serverTimestamp, Timestamp, Bytes} from 'firebase/firestore';

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
const birth = Timestamp.fromMillis(Date.UTC(2001, 0, 15)); // January 2001
const verifiedDb = (uid) => env.authenticatedContext(uid, {email_verified: true}).firestore();
const unverifiedDb = (uid) => env.authenticatedContext(uid, {email_verified: false}).firestore();

function answers(gender) {
  return {name: gender === 'female' ? 'Hodan' : 'Ahmed', gender, nationality: 'SO', residenceCountry: 'GB', city: 'London', ethnicity: 'somali', ethnicityOther: '', profession: 'nurse', professionOther: '', education: 'bachelors', practice: 'active', marriageTimeline: 'withinYear', relocation: 'open', maritalStatus: 'neverMarried', about: 'Seeking a respectful marriage.'};
}
async function seed(uid, gender, {photos = [id(1), id(2)], blurred, verification} = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'profiles', uid), {schemaVersion: 2, ...answers(gender), onboardingComplete: true, createdAt: created, updatedAt: created});
    await setDoc(doc(db, 'privateAccounts', uid), {schemaVersion: 2, adultConfirmed: true, birthDate: birth, phoneCountry: 'GB', phoneNumber: '+447700900123', createdAt: created, updatedAt: created});
    await setDoc(doc(db, 'profilePhotos', uid), {schemaVersion: 1, photoIds: photos, updatedAt: created, ...(blurred === undefined ? {} : {blurred})});
    if (verification) await setDoc(doc(db, 'verifications', uid), {schemaVersion: 1, status: verification, selfieId: id(9)});
  });
}
function listing(gender, extra = {}) {
  return {schemaVersion: 1, ...answers(gender), birthYearMonth: 200101, photoIds: [id(1), id(2)], photosBlurred: false, verified: false, updatedAt: serverTimestamp(), ...extra};
}
const list = (db, uid, data) => setDoc(doc(db, 'publicProfiles', uid), data);
async function listBoth({herBlur = false} = {}) {
  await seed('her', 'female', {blurred: herBlur});
  await seed('him', 'male');
  await seed('other', 'female');
  await list(verifiedDb('her'), 'her', listing('female', {photosBlurred: herBlur}));
  await list(verifiedDb('him'), 'him', listing('male'));
  await list(verifiedDb('other'), 'other', listing('female'));
}
const file = () => ({schemaVersion: 1, contentType: 'image/jpeg', data: Bytes.fromUint8Array(new Uint8Array([0xff, 0xd8, 0xff, 1])), createdAt: serverTimestamp()});
async function seedFiles(uid) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'profilePhotoFiles', uid, 'items', id(1)), {data: 'original'});
    await setDoc(doc(db, 'profilePhotoBlurFiles', uid, 'items', id(1)), {data: 'blurred'});
  });
}

test('a listing must match the owner records exactly', async () => {
  await seed('her', 'female');
  const db = verifiedDb('her');
  for (const bad of [
    {name: 'Someone Else'}, {gender: 'male'}, {birthYearMonth: 199001}, {birthYearMonth: 200102},
    {photoIds: [id(1)]}, {photosBlurred: true}, {verified: true}, {phoneNumber: '+447700900123'},
    {birthDate: birth}, {admin: true}, {updatedAt: new Date(0)},
  ]) {
    await assertFails(list(db, 'her', listing('female', bad)));
  }
  await assertFails(list(unverifiedDb('her'), 'her', listing('female')));
  await assertFails(list(verifiedDb('him'), 'her', listing('female')));
  await assertSucceeds(list(db, 'her', listing('female')));
});

test('verified badge and blur flag follow the source records', async () => {
  await seed('her', 'female', {blurred: true, verification: 'verified'});
  await assertFails(list(verifiedDb('her'), 'her', listing('female', {photosBlurred: true})));
  await assertSucceeds(list(verifiedDb('her'), 'her', listing('female', {photosBlurred: true, verified: true})));
  await seed('pending', 'female', {verification: 'pending'});
  await assertFails(list(verifiedDb('pending'), 'pending', listing('female', {verified: true})));
  await assertSucceeds(list(verifiedDb('pending'), 'pending', listing('female')));
});

test('a profile without photos cannot be listed; men cannot blur', async () => {
  await seed('her', 'female', {photos: []});
  await assertFails(list(verifiedDb('her'), 'her', listing('female', {photoIds: []})));
  await seed('him', 'male');
  const db = verifiedDb('him');
  await assertFails(setDoc(doc(db, 'profilePhotos', 'him'), {schemaVersion: 1, photoIds: [id(1)], blurred: true, updatedAt: serverTimestamp()}));
  await assertSucceeds(setDoc(doc(db, 'profilePhotos', 'him'), {schemaVersion: 1, photoIds: [id(1)], blurred: false, updatedAt: serverTimestamp()}));
});

test('listed members see only the opposite gender', async () => {
  await listBoth();
  await assertSucceeds(getDoc(doc(verifiedDb('him'), 'publicProfiles', 'her')));
  await assertFails(getDoc(doc(verifiedDb('other'), 'publicProfiles', 'her')));
  await seed('lurker', 'male');
  await assertFails(getDoc(doc(verifiedDb('lurker'), 'publicProfiles', 'her')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'publicProfiles', 'her')));
  const him = verifiedDb('him');
  const women = await assertSucceeds(getDocs(query(collection(him, 'publicProfiles'), where('gender', '==', 'female'), orderBy('updatedAt', 'desc'))));
  if (women.size !== 2) throw new Error(`expected 2 listings, got ${women.size}`);
  await assertFails(getDocs(query(collection(him, 'publicProfiles'), where('gender', '==', 'male'))));
  await assertFails(getDocs(collection(him, 'publicProfiles')));
  await assertFails(getDocs(query(collection(verifiedDb('lurker'), 'publicProfiles'), where('gender', '==', 'female'))));
});

test('profile and photo changes must remove the listing in the same write', async () => {
  await seed('her', 'female');
  const db = verifiedDb('her');
  await list(db, 'her', listing('female'));
  const p = {schemaVersion: 2, ...answers('female'), city: 'Leeds', onboardingComplete: true, createdAt: created, updatedAt: serverTimestamp()};
  const a = {schemaVersion: 2, adultConfirmed: true, birthDate: birth, phoneCountry: 'GB', phoneNumber: '+447700900123', createdAt: created, updatedAt: serverTimestamp()};
  const edit = (withUnlist) => { const b = writeBatch(db); b.set(doc(db, 'profiles', 'her'), p); b.set(doc(db, 'privateAccounts', 'her'), a); if (withUnlist) b.delete(doc(db, 'publicProfiles', 'her')); return b.commit(); };
  await assertFails(edit(false));
  await assertSucceeds(edit(true));
  await list(db, 'her', listing('female', {city: 'Leeds'}));
  const reorder = (withUnlist) => { const b = writeBatch(db); b.set(doc(db, 'profilePhotos', 'her'), {schemaVersion: 1, photoIds: [id(1)], updatedAt: serverTimestamp()}); if (withUnlist) b.delete(doc(db, 'publicProfiles', 'her')); return b.commit(); };
  await assertFails(reorder(false));
  await assertSucceeds(reorder(true));
});

test('original photos follow the blur setting; blurred copies are visible to eligible viewers', async () => {
  await listBoth();
  await seedFiles('her');
  const original = (uid) => getDoc(doc(verifiedDb(uid), 'profilePhotoFiles', 'her', 'items', id(1)));
  const blurred = (uid) => getDoc(doc(verifiedDb(uid), 'profilePhotoBlurFiles', 'her', 'items', id(1)));
  await assertSucceeds(original('him'));
  await assertSucceeds(blurred('him'));
  await assertFails(original('other'));
  await assertFails(blurred('other'));
  await assertSucceeds(original('her'));
});

test('blurred photos need her approval; requests and access are private to the pair', async () => {
  await listBoth({herBlur: true});
  await seedFiles('her');
  const him = verifiedDb('him');
  const her = verifiedDb('her');
  await assertFails(getDoc(doc(him, 'profilePhotoFiles', 'her', 'items', id(1))));
  await assertSucceeds(getDoc(doc(him, 'profilePhotoBlurFiles', 'her', 'items', id(1))));

  const request = doc(him, 'photoRequests', 'her', 'items', 'him');
  await assertFails(setDoc(doc(him, 'photoRequests', 'her', 'items', 'other'), {createdAt: serverTimestamp()}));
  await assertFails(setDoc(request, {createdAt: serverTimestamp(), note: 'hi'}));
  await assertSucceeds(setDoc(request, {createdAt: serverTimestamp()}));
  await assertSucceeds(getDoc(request));
  await assertFails(getDocs(collection(him, 'photoRequests', 'her', 'items')));
  await assertSucceeds(getDocs(collection(her, 'photoRequests', 'her', 'items')));
  await assertFails(getDoc(doc(verifiedDb('other'), 'photoRequests', 'her', 'items', 'him')));

  await assertFails(setDoc(doc(him, 'photoAccess', 'her', 'items', 'him'), {grantedAt: serverTimestamp()}));
  const approve = writeBatch(her);
  approve.set(doc(her, 'photoAccess', 'her', 'items', 'him'), {grantedAt: serverTimestamp()});
  approve.delete(doc(her, 'photoRequests', 'her', 'items', 'him'));
  await assertSucceeds(approve.commit());
  await assertSucceeds(getDoc(doc(him, 'profilePhotoFiles', 'her', 'items', id(1))));
  await assertSucceeds(getDoc(doc(him, 'photoAccess', 'her', 'items', 'him')));
  await assertFails(setDoc(request, {createdAt: serverTimestamp()}));

  await assertSucceeds(deleteDoc(doc(her, 'photoAccess', 'her', 'items', 'him')));
  await assertFails(getDoc(doc(him, 'profilePhotoFiles', 'her', 'items', id(1))));
});

test('requests are only for listings that blur', async () => {
  await listBoth();
  await assertFails(setDoc(doc(verifiedDb('him'), 'photoRequests', 'her', 'items', 'him'), {createdAt: serverTimestamp()}));
});

test('listings may carry the join date, which must match the profile', async () => {
  await seed('her', 'female');
  const db = verifiedDb('her');
  await assertFails(list(db, 'her', listing('female', {joinedAt: Timestamp.fromMillis(Date.UTC(2025, 0, 1))})));
  await assertSucceeds(list(db, 'her', listing('female', {joinedAt: created})));
  // Older app versions still write listings without it.
  await assertSucceeds(list(db, 'her', listing('female')));
});

test('"New members" is a query listed members may run', async () => {
  await listBoth();
  const him = verifiedDb('him');
  await assertSucceeds(getDocs(query(collection(him, 'publicProfiles'), where('gender', '==', 'female'), orderBy('joinedAt', 'desc'))));
  await assertSucceeds(getDocs(query(collection(him, 'publicProfiles'), where('gender', '==', 'female'), where('residenceCountry', 'in', ['GB', 'SO']), orderBy('updatedAt', 'desc'))));
});

const prefs = (extra = {}) => ({schemaVersion: 1, minAge: 22, maxAge: 35, countries: ['GB', 'SO'], maritalStatuses: ['neverMarried'], practices: ['active'], updatedAt: serverTimestamp(), ...extra});

test('partner preferences are private and well formed', async () => {
  const ref = (viewer) => doc(verifiedDb(viewer), 'partnerPreferences', 'her');
  await assertSucceeds(setDoc(ref('her'), prefs()));
  await assertSucceeds(getDoc(ref('her')));
  await assertFails(getDoc(ref('him')));
  await assertFails(setDoc(ref('him'), prefs()));
  for (const bad of [
    {minAge: 17}, {maxAge: 81}, {minAge: 40, maxAge: 30}, {minAge: '22'},
    {countries: ['gb']}, {countries: ['GBR']}, {countries: Array(11).fill('GB')},
    {maritalStatuses: ['married']}, {practices: ['none']}, {extra: 1},
    {updatedAt: created},
  ]) {
    await assertFails(setDoc(ref('her'), prefs(bad)));
  }
  await assertSucceeds(setDoc(ref('her'), prefs({countries: [], maritalStatuses: [], practices: []})));
  await assertSucceeds(deleteDoc(ref('her')));
});
test('deleting the profile pair may remove partner preferences in the same write', async () => {
  await seed('her', 'female');
  const db = verifiedDb('her');
  await assertSucceeds(setDoc(doc(db, 'partnerPreferences', 'her'), prefs()));
  const batch = writeBatch(db);
  batch.delete(doc(db, 'profiles', 'her'));
  batch.delete(doc(db, 'privateAccounts', 'her'));
  batch.delete(doc(db, 'partnerPreferences', 'her'));
  await assertSucceeds(batch.commit());
});