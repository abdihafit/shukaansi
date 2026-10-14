import 'dart:async';

import 'package:shukaansi/models/chat.dart';
import 'package:shukaansi/services/chat_service.dart';

/// In-memory conversations that update live like Firestore snapshots.
class TestChats implements ChatService {
  final Map<String, List<ChatMessage>> threads = {};
  final Map<String, DateTime> readAt = {};
  final _changes = StreamController<void>.broadcast();
  bool failSend = false;
  final sent = <String>[];
  var _clock = DateTime(2026, 9, 29, 9);

  DateTime _tick() => _clock = _clock.add(const Duration(minutes: 1));

  /// A message from [other] arriving.
  void receive(String other, String text) {
    (threads[other] ??= []).add(
      ChatMessage(
        id: 'm${threads.length}-${threads[other]!.length}',
        from: other,
        text: text,
        sentAt: _tick(),
      ),
    );
    _changes.add(null);
  }

  List<ChatSummary> _summaries() {
    final list = [
      for (final MapEntry(key: other, value: messages) in threads.entries)
        if (messages.isNotEmpty)
          ChatSummary(
            otherUid: other,
            lastText: messagePreview(messages.last.text),
            lastFrom: messages.last.from,
            lastAt: messages.last.sentAt!,
            readAt: readAt[other],
          ),
    ];
    return list..sort((a, b) => b.lastAt.compareTo(a.lastAt));
  }

  @override
  Stream<List<ChatSummary>> conversations(String uid) async* {
    yield _summaries();
    await for (final _ in _changes.stream) {
      yield _summaries();
    }
  }

  @override
  Stream<List<ChatMessage>> messages(String uid, String other) async* {
    yield [...?threads[other]];
    await for (final _ in _changes.stream) {
      yield [...?threads[other]];
    }
  }

  @override
  Future<void> send(String uid, String other, String text) async {
    if (failSend) throw const ChatException();
    sent.add('$other: $text');
    final time = _tick();
    (threads[other] ??= []).add(
      ChatMessage(id: 's${sent.length}', from: uid, text: text, sentAt: time),
    );
    readAt[other] = time;
    _changes.add(null);
  }

  @override
  Future<void> markRead(String uid, String other) async {
    final last = threads[other]?.lastOrNull?.sentAt;
    if (last == null || readAt[other] == last) return;
    readAt[other] = last;
    _changes.add(null);
  }
}
