import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../services/chat_service.dart';

/// The member's conversations, kept live while the app is open.
class ChatController extends ChangeNotifier {
  ChatController({required this.uid, required this.service});
  final String uid;
  final ChatService service;

  List<ChatSummary> conversations = const [];
  bool loaded = false;
  bool failed = false;
  StreamSubscription<List<ChatSummary>>? _subscription;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void start() {
    if (_subscription != null) return;
    _subscription = service
        .conversations(uid)
        .listen(
          (value) {
            conversations = value;
            loaded = true;
            failed = false;
            _notify();
          },
          onError: (Object _) {
            failed = true;
            _notify();
          },
        );
  }

  void retry() {
    _subscription?.cancel();
    _subscription = null;
    failed = false;
    _notify();
    start();
  }

  ChatSummary? withMember(String other) {
    for (final c in conversations) {
      if (c.otherUid == other) return c;
    }
    return null;
  }

  /// Unread conversations among [members] (current matches only).
  int unreadAmong(Set<String> members) => conversations
      .where((c) => c.unread && members.contains(c.otherUid))
      .length;

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
