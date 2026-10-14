import {before, after, beforeEach, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, setDoc, deleteDoc, updateDoc, serverTimestamp, Bytes, writeBatch} from 'firebase/firestore';
import {ref, uploadBytes, getBytes, deleteObject} from 'firebase/storage';

let env;
const rules = async (file) => readFile(new URL(`../../${file}`, import.meta.url), 'utf8');
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-kumee',
    firestore: {host: '127.0.0.1', port: 8080, rules: await rules('firestore.rules')},
    storage: {host: '127.0.0.1', port: 9199, rules: await rules('storage.rules')},
  });
});
beforeEach(async () => { await env.clearFirestore(); await env.clearStorage(); });
after(async () => env?.cleanup());

const id = (n) => `Photo${String(n).padStart(15, '0')}`; // 20 alphanumeric characters
const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4]);
const image = {contentType: 'image/jpeg'};
const db = (uid) => env.authenticatedContext(uid).firestore();
const storage = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).storage();
const photos = (ids) => ({schemaVersion: 1, photoIds: ids, updatedAt: serverTimestamp()});
const submission = (selfieId = id(9), gender = 'female') => ({schemaVersion: 1, status: 'pending', selfieId, gender, submittedAt: serverTimestamp()});

async function seedProfile(uid = 'owner') {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'profiles', uid), {schemaVersion: 2, gender: 'female'});
  });
}
async function seedPhotos(uid = 'owner', ids = [id(1)]) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'profilePhotos', uid), {schemaVersion: 1, photoIds: ids});
  });
}
async function adminSets(status, uid = 'owner') {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'verifications', uid), {schemaVersion: 1, status, selfieId: id(9), reviewNote: 'Face not visible'});
  });
}

test('owner stores photo order after creating a profile', async () => {
  await assertFails(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos([id(1)])));
  await seedProfile();
  await assertSucceeds(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos([id(1), id(2)])));
  await assertSucceeds(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos([id(2), id(1)])));
  await assertSucceeds(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos([])));
  await assertSucceeds(getDoc(doc(db('owner'), 'profilePhotos', 'owner')));
  await assertSucceeds(deleteDoc(doc(db('owner'), 'profilePhotos', 'owner')));
});

test('photo lists are limited, unique, well-formed and private', async () => {
  await seedProfile();
  const ref6 = [1, 2, 3, 4, 5, 6].map(id);
  await assertSucceeds(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos(ref6)));
  for (const bad of [[...ref6, id(7)], [id(1), id(1)], ['short'], [id(1), 'bad id with spaces..'], [1]]) {
    await assertFails(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos(bad)));
  }
  await assertFails(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), {...photos([id(1)]), approved: true}));
  await assertFails(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), {...photos([id(1)]), updatedAt: new Date(0)}));
  await assertFails(getDoc(doc(db('other'), 'profilePhotos', 'owner')));
  await assertFails(setDoc(doc(db('other'), 'profilePhotos', 'owner'), photos([id(1)])));
});

test('verification can be requested only with a photo, only as pending', async () => {
  await seedProfile();
  await assertFails(setDoc(doc(db('owner'), 'verifications', 'owner'), submission()));
  await seedPhotos('owner', []);
  await assertFails(setDoc(doc(db('owner'), 'verifications', 'owner'), submission()));
  await seedPhotos();
  for (const status of ['verified', 'rejected']) {
    await assertFails(setDoc(doc(db('owner'), 'verifications', 'owner'), {...submission(), status}));
  }
  await assertFails(setDoc(doc(db('owner'), 'verifications', 'owner'), {...submission(), reviewNote: 'self'}));
  await assertFails(setDoc(doc(db('owner'), 'verifications', 'owner'), submission('bad')));
  await assertFails(setDoc(doc(db('owner'), 'verifications', 'owner'), submission(id(9), 'male')));
  await assertFails(setDoc(doc(db('other'), 'verifications', 'owner'), submission()));
  await assertSucceeds(setDoc(doc(db('owner'), 'verifications', 'owner'), submission()));
  await assertSucceeds(getDoc(doc(db('owner'), 'verifications', 'owner')));
  await assertFails(getDoc(doc(db('other'), 'verifications', 'owner')));
});

test('owners cannot change a pending or verified decision, but can resubmit after rejection', async () => {
  await seedProfile();
  await seedPhotos();
  await adminSets('pending');
  await assertFails(setDoc(doc(db('owner'), 'verifications', 'owner'), submission(id(8))));
  await assertFails(updateDoc(doc(db('owner'), 'verifications', 'owner'), {status: 'verified'}));
  await adminSets('verified');
  await assertFails(setDoc(doc(db('owner'), 'verifications', 'owner'), submission(id(8))));
  await adminSets('rejected');
  await assertSucceeds(setDoc(doc(db('owner'), 'verifications', 'owner'), submission(id(8))));
  await assertSucceeds(deleteDoc(doc(db('owner'), 'verifications', 'owner')));
});

test('profile photo files: owner-only, images under 5 MB, never overwritten', async () => {
  const path = (uid, name = id(1)) => `profilePhotos/${uid}/${name}`;
  await assertSucceeds(uploadBytes(ref(storage('owner'), path('owner')), jpeg, image));
  await assertSucceeds(getBytes(ref(storage('owner'), path('owner'))));
  await assertFails(getBytes(ref(storage('other'), path('owner'))));
  await assertFails(getBytes(ref(storage(null), path('owner'))));
  await assertFails(uploadBytes(ref(storage('owner'), path('owner')), jpeg, image));
  await assertFails(uploadBytes(ref(storage('other'), path('owner', id(2))), jpeg, image));
  await assertFails(uploadBytes(ref(storage('owner'), path('owner', 'x.jpg')), jpeg, image));
  await assertFails(uploadBytes(ref(storage('owner'), path('owner', id(3))), jpeg, {contentType: 'image/svg+xml'}));
  await assertFails(uploadBytes(ref(storage('owner'), path('owner', id(4))), new Uint8Array(5 * 1024 * 1024), image));
  await assertFails(deleteObject(ref(storage('other'), path('owner'))));
  await assertSucceeds(deleteObject(ref(storage('owner'), path('owner'))));
});

test('verification selfies cannot be read by any client', async () => {
  const path = `verificationSelfies/owner/${id(9)}`;
  await assertSucceeds(uploadBytes(ref(storage('owner'), path), jpeg, image));
  await assertFails(getBytes(ref(storage('owner'), path)));
  await assertFails(getBytes(ref(storage('other'), path)));
  await assertFails(uploadBytes(ref(storage('other'), `verificationSelfies/owner/${id(8)}`), jpeg, image));
  await assertSucceeds(deleteObject(ref(storage('owner'), path)));
  await assertFails(uploadBytes(ref(storage('owner'), `elsewhere/owner/${id(1)}`), jpeg, image));
});

const file = (data = jpeg, contentType = 'image/jpeg') => ({schemaVersion: 1, contentType, data: Bytes.fromUint8Array(data), createdAt: serverTimestamp()});
const photoDoc = (d, uid = 'owner', name = id(1)) => doc(d, 'profilePhotoFiles', uid, 'items', name);
const selfieDoc = (d, uid = 'owner', name = id(9)) => doc(d, 'verificationSelfieFiles', uid, 'items', name);

test('free-plan photo files: owner-only, images up to 900 KB, never overwritten', async () => {
  await assertSucceeds(setDoc(photoDoc(db('owner')), file()));
  await assertSucceeds(getDoc(photoDoc(db('owner'))));
  await assertFails(getDoc(photoDoc(db('other'))));
  await assertFails(getDoc(photoDoc(env.unauthenticatedContext().firestore())));
  await assertFails(setDoc(photoDoc(db('owner')), file()));
  await assertFails(setDoc(photoDoc(db('other'), 'owner', id(2)), file()));
  await assertFails(setDoc(photoDoc(db('owner'), 'owner', 'bad'), file()));
  await assertFails(setDoc(photoDoc(db('owner'), 'owner', id(3)), file(jpeg, 'image/svg+xml')));
  await assertFails(setDoc(photoDoc(db('owner'), 'owner', id(4)), file(new Uint8Array(0))));
  await assertFails(setDoc(photoDoc(db('owner'), 'owner', id(5)), file(new Uint8Array(900 * 1024 + 1))));
  await assertSucceeds(setDoc(photoDoc(db('owner'), 'owner', id(6)), file(new Uint8Array(900 * 1024))));
  await assertFails(setDoc(photoDoc(db('owner'), 'owner', id(7)), {...file(), data: 'not bytes'}));
  await assertFails(setDoc(photoDoc(db('owner'), 'owner', id(8)), {...file(), extra: true}));
  await assertFails(setDoc(photoDoc(db('owner'), 'owner', id(10)), {...file(), createdAt: new Date(0)}));
  await assertFails(deleteDoc(photoDoc(db('other'))));
  await assertSucceeds(deleteDoc(photoDoc(db('owner'))));
});

test('free-plan selfie files cannot be read by any client', async () => {
  await assertSucceeds(setDoc(selfieDoc(db('owner')), file()));
  await assertFails(getDoc(selfieDoc(db('owner'))));
  await assertFails(getDoc(selfieDoc(db('other'))));
  await assertFails(setDoc(selfieDoc(db('owner')), file()));
  await assertFails(setDoc(selfieDoc(db('other'), 'owner', id(8)), file()));
  await assertSucceeds(deleteDoc(selfieDoc(db('owner'))));
});

test('changing the main photo must clear verification in the same write', async () => {
  await seedProfile();
  await seedPhotos('owner', [id(1), id(2), id(3)]);
  for (const status of ['pending', 'verified', 'rejected']) {
    await adminSets(status);
    await assertFails(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos([id(2), id(1), id(3)])));
    await assertFails(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos([id(2), id(3)])));
    await assertFails(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos([])));
    // Changes that keep the main photo are fine.
    await assertSucceeds(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos([id(1), id(3), id(2)])));
    await assertSucceeds(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos([id(1), id(3)])));
    await seedPhotos('owner', [id(1), id(2), id(3)]);
  }
  await adminSets('verified');
  const owner = db('owner');
  const reset = writeBatch(owner);
  reset.set(doc(owner, 'profilePhotos', 'owner'), photos([id(2), id(1), id(3)]));
  reset.delete(doc(owner, 'verifications', 'owner'));
  await assertSucceeds(reset.commit());
  // With no verification record the main photo can change freely.
  await assertSucceeds(setDoc(doc(db('owner'), 'profilePhotos', 'owner'), photos([id(3), id(2), id(1)])));
});
