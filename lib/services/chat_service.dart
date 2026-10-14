import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat.dart';
import '../models/interest.dart';

class ChatException implements Exception {
  const ChatException();
}

/// One-to-one messages between matched members. Rules allow a message only
/// while the match exists and every required Wali has approved.
abstract interface class ChatService {
  /// The viewer's conversations, newest first, kept up to date.
  Stream<List<ChatSummary>> conversations(String uid);

  /// Messages with [other], oldest first, kept up to date.
  Stream<List<ChatMessage>> messages(String uid, String other);

  Future<void> send(String uid, String other, String text);

  /// Records that the viewer has seen the conversation.
  Future<void> markRead(String uid, String other);
}

class UnavailableChatService implements ChatService {
  const UnavailableChatService();
  @override
  Stream<List<ChatSummary>> conversations(String uid) =>
      Stream.error(const ChatException());
  @override
  Stream<List<ChatMessage>> messages(String uid, String other) =>
      Stream.error(const ChatException());
  @override
  Future<void> send(String uid, String other, String text) async =>
      throw const ChatException();
  @override
  Future<void> markRead(String uid, String other) async =>
      throw const ChatException();
}

/// Deletes a conversation and its messages; used when a match ends.
/// Missing conversations are fine.
Future<void> deleteChat(FirebaseFirestore store, String a, String b) async {
  final chat = store.collection('chats').doc(matchIdFor(a, b));
  while (true) {
    final page = await chat
        .collection('messages')
        .limit(400)
        .get(const GetOptions(source: Source.server));
    if (page.docs.isEmpty) break;
    final batch = store.batch();
    for (final doc in page.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
  await chat.delete();
}

class FirestoreChatService implements ChatService {
  FirestoreChatService(this._store, this._auth);
  final FirebaseFirestore _store;
  final FirebaseAuth _auth;
  static const _messageLimit = 200;

  DocumentReference<Map<String, dynamic>> _chat(String a, String b) =>
      _store.collection('chats').doc(matchIdFor(a, b));

  void _check(String uid) {
    if (uid.isEmpty || _auth.currentUser?.uid != uid) {
      throw const ChatException();
    }
  }

  static DateTime? _time(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  @override
  Stream<List<ChatSummary>> conversations(String uid) {
    _check(uid);
    return _store
        .collection('chats')
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final list = <ChatSummary>[];
          for (final doc in snapshot.docs) {
            final d = doc.data();
            final users = (d['users'] as List?)?.cast<String>() ?? const [];
            final other = users.firstWhere((u) => u != uid, orElse: () => '');
            final lastAt = _time(d['lastAt']);
            if (other.isEmpty || lastAt == null) continue;
            list.add(
              ChatSummary(
                otherUid: other,
                lastText: d['lastText'] as String? ?? '',
                lastFrom: d['lastFrom'] as String? ?? '',
                lastAt: lastAt,
                readAt: _time((d['readBy'] as Map?)?[uid]),
              ),
            );
          }
          return list..sort((a, b) => b.lastAt.compareTo(a.lastAt));
        })
        .handleError((Object _) => throw const ChatException());
  }

  @override
  Stream<List<ChatMessage>> messages(String uid, String other) {
    _check(uid);
    return _chat(uid, other)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(_messageLimit)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs.reversed)
              ChatMessage(
                id: doc.id,
                from: doc.data()['from'] as String? ?? '',
                text: doc.data()['text'] as String? ?? '',
                // Null until the server confirms a just-sent message.
                sentAt: _time(doc.data()['sentAt']),
              ),
          ],
        )
        .handleError((Object _) => throw const ChatException());
  }

  @override
  Future<void> send(String uid, String other, String text) async {
    _check(uid);
    final body = text.trim();
    if (body.isEmpty || body.length > maxMessageLength) {
      throw const ChatException();
    }
    final chat = _chat(uid, other);
    final now = FieldValue.serverTimestamp();
    try {
      final exists = (await chat.get()).exists;
      final users = [uid, other]..sort();
      final batch = _store.batch()
        ..set(chat.collection('messages').doc(), {
          'from': uid,
          'text': body,
          'sentAt': now,
        });
      if (exists) {
        batch.update(chat, {
          'lastText': messagePreview(body),
          'lastFrom': uid,
          'lastAt': now,
          'readBy.$uid': now,
        });
      } else {
        batch.set(chat, {
          'users': users,
          'lastText': messagePreview(body),
          'lastFrom': uid,
          'lastAt': now,
          'readBy': {uid: now},
        });
      }
      await batch.commit();
    } catch (_) {
      throw const ChatException();
    }
  }

  @override
  Future<void> markRead(String uid, String other) async {
    _check(uid);
    try {
      await _chat(
        uid,
        other,
      ).update({'readBy.$uid': FieldValue.serverTimestamp()});
    } catch (_) {
      // No conversation yet, or offline; it is marked next time.
    }
  }
}
