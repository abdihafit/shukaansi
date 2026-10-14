import 'matrimonial_profile.dart';

/// Age in whole years from a `yyyymm` value. Listings publish only the year and
/// month of birth, so the result can be a month early near a birthday.
int ageFromYearMonth(int yearMonth, DateTime today) {
  final year = yearMonth ~/ 100;
  final month = yearMonth % 100;
  return today.year - year - (today.month < month ? 1 : 0);
}

/// A member as others see them in Discover. Never contains the phone number
/// or exact birth date.
class ProfileCard {
  const ProfileCard({
    required this.uid,
    required this.profile,
    required this.birthYearMonth,
    required this.photoIds,
    required this.photosBlurred,
    required this.verified,
  });
  final String uid;
  final MatrimonialProfile profile;
  final int birthYearMonth;
  final List<String> photoIds;
  final bool photosBlurred;

  /// Approved by the review team; shown as a blue check.
  final bool verified;

  int ageOn(DateTime today) => ageFromYearMonth(birthYearMonth, today);

  factory ProfileCard.fromMap(String uid, Map<String, dynamic> data) {
    // Listings carry the same answers as a saved profile.
    final profile = MatrimonialProfile.fromMap({
      ...data,
      'schemaVersion': profileSchemaVersion,
      'onboardingComplete': true,
    });
    final yearMonth = data['birthYearMonth'];
    final photos = data['photoIds'];
    if (yearMonth is! int || photos is! List) {
      throw const FormatException('Invalid listing');
    }
    return ProfileCard(
      uid: uid,
      profile: profile,
      birthYearMonth: yearMonth,
      photoIds: photos.cast<String>(),
      photosBlurred: data['photosBlurred'] == true,
      verified: data['verified'] == true,
    );
  }
}

/// Why the owner is not yet visible in Discover.
enum ListingGap { emailNotVerified, noPhoto }

class ListingStatus {
  const ListingStatus(this.missing);
  final Set<ListingGap> missing;
  bool get listed => missing.isEmpty;
}

/// What a member is looking for in a spouse. Saved as their partner
/// preferences and used to choose the "For you" feed.
class DiscoveryFilter {
  const DiscoveryFilter({
    this.minAge = minAllowedAge,
    this.maxAge = maxAllowedAge,
    this.countries = const {},
    this.maritalStatuses = const {},
    this.practices = const {},
  });
  static const minAllowedAge = 18;
  static const maxAllowedAge = 80;

  /// A Firestore "in" query allows up to 30 values; 10 keeps choices focused.
  static const maxCountries = 10;

  final int minAge;
  final int maxAge;

  /// Residence countries (ISO codes); empty means any.
  final Set<String> countries;
  final Set<MaritalStatus> maritalStatuses;
  final Set<PracticeLevel> practices;

  bool get isDefault =>
      minAge == minAllowedAge &&
      maxAge == maxAllowedAge &&
      countries.isEmpty &&
      maritalStatuses.isEmpty &&
      practices.isEmpty;

  Map<String, Object> toMap() => {
    'minAge': minAge,
    'maxAge': maxAge,
    'countries': countries.toList()..sort(),
    'maritalStatuses': [for (final m in maritalStatuses) m.name]..sort(),
    'practices': [for (final p in practices) p.name]..sort(),
  };

  /// Unknown values are dropped rather than failing the whole record.
  factory DiscoveryFilter.fromMap(Map<String, dynamic> data) {
    Set<T> names<T extends Enum>(Object? list, List<T> values) => {
      if (list is List)
        for (final name in list) ...values.where((v) => v.name == name),
    };
    int age(Object? value, int fallback) =>
        value is int ? value.clamp(minAllowedAge, maxAllowedAge) : fallback;
    final min = age(data['minAge'], minAllowedAge);
    final max = age(data['maxAge'], maxAllowedAge);
    final countries = data['countries'];
    return DiscoveryFilter(
      minAge: min <= max ? min : max,
      maxAge: min <= max ? max : min,
      countries: {
        if (countries is List)
          for (final c in countries.take(maxCountries))
            if (c is String) c,
      },
      maritalStatuses: names(data['maritalStatuses'], MaritalStatus.values),
      practices: names(data['practices'], PracticeLevel.values),
    );
  }

  /// Countries are applied by the query; the rest on the device.
  bool matches(ProfileCard card, DateTime today) {
    final age = card.ageOn(today);
    return age >= minAge &&
        (maxAge >= maxAllowedAge || age <= maxAge) &&
        (maritalStatuses.isEmpty ||
            maritalStatuses.contains(card.profile.maritalStatus)) &&
        (practices.isEmpty || practices.contains(card.profile.practice));
  }
}

class DiscoveryPage {
  const DiscoveryPage(this.cards, {this.cursor, this.hasMore = false});
  final List<ProfileCard> cards;

  /// Opaque position for the next page.
  final Object? cursor;
  final bool hasMore;
}

/// The two Discover feeds.
enum DiscoverFeed {
  /// Members who suit the viewer's partner preferences, recently active first.
  forYou,

  /// Everyone, newest members first.
  newMembers,
}

/// The viewer's standing with a member who blurs her photos.
enum PhotoAccess { none, requested, granted }
