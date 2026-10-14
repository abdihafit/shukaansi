import {before, after, beforeEach, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, query, where, orderBy, writeBatch, serverTimestamp, Timestamp} from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-kumee',
    firestore: {host: '127.0.0.1', port: 8080, rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8')},
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => env?.cleanup());

const created = Timestamp.fromMillis(Date.UTC(2026, 0, 1));
const db = (uid) => env.authenticatedContext(uid, {email_verified: true}).firestore();
async function admin(fn) { await env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore())); }

// her (sister) and him (brother), matched; her Wali decides.
async function setup({herApproved = true, matched = true, herWali = true} = {}) {
  await admin(async (d) => {
    await setDoc(doc(d, 'profiles', 'her'), {gender: 'female'});
    await setDoc(doc(d, 'profiles', 'him'), {gender: 'male'});
    if (matched) await setDoc(doc(d, 'matches', 'her_him'), {users: ['her', 'him'], createdAt: created});
    if (herWali) {
      await setDoc(doc(d, 'walis', 'her'), {waliUid: 'wali', waliName: 'Abdi', memberName: 'Hodan', inviteCode: 'ABCD2345', linkedAt: created});
      await setDoc(doc(d, 'waliRequests', 'her_him'), {memberUid: 'her', otherUid: 'him', waliUid: 'wali', status: herApproved ? 'approved' : 'pending', candidate: {}, createdAt: created});
    }
  });
}

// Sends the way the app does: message plus summary in one batch.
function send(uid, text = 'Assalamu alaikum', {first = true, extra = {}} = {}) {
  const d = db(uid);
  const batch = writeBatch(d);
  batch.set(doc(collection(d, 'chats', 'her_him', 'messages')), {from: uid, text, sentAt: serverTimestamp(), ...extra});
  const summary = {lastText: text.slice(0, 140), lastFrom: uid, lastAt: serverTimestamp()};
  if (first) {
    batch.set(doc(d, 'chats', 'her_him'), {users: ['her', 'him'], ...summary, readBy: {[uid]: serverTimestamp()}});
  } else {
    batch.update(doc(d, 'chats', 'her_him'), {...summary, [`readBy.${uid}`]: serverTimestamp()});
  }
  return batch.commit();
}

test('approved matches can message both ways', async () => {
  await setup();
  await assertSucceeds(send('him'));
  await assertSucceeds(send('her', 'Wa alaikum assalam', {first: false}));
  await assertSucceeds(getDocs(query(collection(db('her'), 'chats', 'her_him', 'messages'), orderBy('sentAt'))));
  await assertSucceeds(getDocs(query(collection(db('him'), 'chats'), where('users', 'array-contains', 'him'))));
});

test('a sister without approval, or without a Wali, cannot message yet', async () => {
  await setup({herApproved: false});
  await assertFails(send('him'));
  await assertFails(send('her'));
  await env.clearFirestore();
  await setup({herWali: false});
  await assertFails(send('him'));
});

test('brothers without a Wali need no approval; one who adds a Wali does', async () => {
  await setup();
  await assertSucceeds(send('him'));
  await admin((d) => setDoc(doc(d, 'walis', 'him'), {waliUid: 'w2', waliName: 'Omar', memberName: 'Ahmed', inviteCode: 'WXYZ6789', linkedAt: created}));
  await assertFails(send('him', 'Hello', {first: false}));
});

test('no match, no messages; outsiders can neither read nor write', async () => {
  await setup({matched: false});
  await assertFails(send('him'));
  await env.clearFirestore();
  await setup();
  await assertSucceeds(send('him'));
  await assertFails(getDocs(collection(db('stranger'), 'chats', 'her_him', 'messages')));
  await assertFails(getDoc(doc(db('stranger'), 'chats', 'her_him')));
  await assertFails(getDoc(doc(db('wali'), 'chats', 'her_him')));
  // After unmatching the messages cannot be read.
  await admin((d) => deleteDoc(doc(d, 'matches', 'her_him')));
  await assertFails(getDocs(collection(db('her'), 'chats', 'her_him', 'messages')));
});

test('messages must be well formed and sent with the summary', async () => {
  await setup();
  await assertFails(send('him', ''));
  await assertFails(send('him', '  padded  '));
  await assertFails(send('him', 'x'.repeat(1001)));
  await assertFails(send('him', 'Hi', {extra: {from: 'her'}}));
  await assertFails(send('him', 'Hi', {extra: {photo: 'x'}}));
  // A message alone, without updating the summary, is refused.
  const d = db('him');
  await assertFails(setDoc(doc(collection(d, 'chats', 'her_him', 'messages')), {from: 'him', text: 'Hi', sentAt: serverTimestamp()}));
});

test('readers mark only their own read time', async () => {
  await setup();
  await assertSucceeds(send('him'));
  await assertSucceeds(updateDoc(doc(db('her'), 'chats', 'her_him'), {'readBy.her': serverTimestamp()}));
  await assertFails(updateDoc(doc(db('her'), 'chats', 'her_him'), {'readBy.him': serverTimestamp()}));
  await assertFails(updateDoc(doc(db('her'), 'chats', 'her_him'), {lastText: 'edited'}));
});

test('suspended members cannot message', async () => {
  await setup();
  await admin((d) => setDoc(doc(d, 'accountStatus', 'him'), {status: 'suspended', reason: 'x', updatedAt: created, updatedBy: 'mod'}));
  await assertFails(send('him'));
});

test('either member clears the conversation', async () => {
  await setup();
  await assertSucceeds(send('him'));
  const msgs = await getDocs(collection(db('her'), 'chats', 'her_him', 'messages'));
  const herDb = db('her');
  const clear = writeBatch(herDb);
  for (const m of msgs.docs) clear.delete(doc(herDb, 'chats', 'her_him', 'messages', m.id));
  clear.delete(doc(herDb, 'chats', 'her_him'));
  await assertSucceeds(clear.commit());
  await assertFails(deleteDoc(doc(db('stranger'), 'chats', 'her_him')));
});
