import 'discovery.dart';

/// Document id of the match between two members: both uids, sorted, so either
/// member derives the same id.
String matchIdFor(String a, String b) =>
    a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';

/// The viewer's standing with another member.
enum InterestState {
  none,

  /// The viewer showed interest; the other member has not yet.
  liked,

  /// The other member showed interest in the viewer.
  likedYou,

  /// Both showed interest.
  matched,

  /// Both showed interest, but neither has Premium yet, so no match.
  mutual,
}

enum LikeResult {
  liked,
  matched,

  /// Both like each other; a match needs Premium on either side (DEC-023).
  mutualNeedsPremium,
}

/// A member in the Likes or Matches lists, with when it happened.
class InterestEntry {
  const InterestEntry(this.card, this.at);
  final ProfileCard card;
  final DateTime at;
}

/// Everything about the viewer's interests, newest first in each list.
/// Members who left Discover or blocked either way are not included.
class InterestSnapshot {
  const InterestSnapshot({
    this.received = const [],
    this.sent = const [],
    this.matches = const [],
  });

  /// Members who showed interest in the viewer, not yet matched.
  final List<InterestEntry> received;

  /// Members the viewer showed interest in, not yet matched.
  final List<InterestEntry> sent;
  final List<InterestEntry> matches;

  InterestState stateOf(String uid) {
    bool has(List<InterestEntry> list) => list.any((e) => e.card.uid == uid);
    if (has(matches)) return InterestState.matched;
    if (has(sent) && has(received)) return InterestState.mutual;
    if (has(sent)) return InterestState.liked;
    if (has(received)) return InterestState.likedYou;
    return InterestState.none;
  }
}
