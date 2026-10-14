/// Longest message a member can send.
const maxMessageLength = 1000;

/// How much of the last message the conversation list keeps.
const maxPreviewLength = 140;

/// One conversation as the list shows it.
class ChatSummary {
  const ChatSummary({
    required this.otherUid,
    required this.lastText,
    required this.lastFrom,
    required this.lastAt,
    this.readAt,
  });
  final String otherUid;
  final String lastText;
  final String lastFrom;
  final DateTime lastAt;

  /// When the viewer last opened it; null if never.
  final DateTime? readAt;

  /// The other member wrote since the viewer last read it.
  bool get unread =>
      lastFrom == otherUid && (readAt == null || readAt!.isBefore(lastAt));
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.from,
    required this.text,
    this.sentAt,
  });
  final String id;
  final String from;
  final String text;

  /// Null while the server time is still pending on a just-sent message.
  final DateTime? sentAt;
}

/// The preview stored with the conversation: one line, short, trimmed.
String messagePreview(String text) {
  final oneLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return oneLine.length <= maxPreviewLength
      ? oneLine
      : oneLine.substring(0, maxPreviewLength).trimRight();
}
