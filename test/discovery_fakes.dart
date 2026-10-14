import 'dart:typed_data';

import 'package:shukaansi/models/discovery.dart';
import 'package:shukaansi/models/matrimonial_profile.dart';
import 'package:shukaansi/services/discovery_service.dart';

import 'media_fakes.dart';

ProfileCard testCard(
  String uid, {
  String name = 'Hodan',
  ProfileGender gender = ProfileGender.female,
  int birthYearMonth = 200101,
  MaritalStatus marital = MaritalStatus.neverMarried,
  PracticeLevel practice = PracticeLevel.active,
  bool blurred = false,
  bool verified = false,
}) => ProfileCard(
  uid: uid,
  profile: MatrimonialProfile(
    name: name,
    gender: gender,
    nationality: 'SO',
    residenceCountry: 'GB',
    city: 'London',
    ethnicity: Ethnicity.somali,
    profession: Profession.nurse,
    education: EducationLevel.bachelors,
    practice: practice,
    marriageTimeline: MarriageTimeline.withinYear,
    relocation: Relocation.open,
    maritalStatus: marital,
    about: 'Seeking a respectful and lasting marriage.',
  ),
  birthYearMonth: birthYearMonth,
  photoIds: [photoId(1), photoId(2)],
  photosBlurred: blurred,
  verified: verified,
);

class TestDiscovery implements DiscoveryService {
  ListingStatus status = const ListingStatus({});
  List<ProfileCard> cards = [];
  bool failSync = false;
  bool failBrowse = false;
  bool failRequest = false;
  int syncs = 0;
  DiscoveryFilter? lastFilter;
  final Map<String, PhotoAccess> access = {};
  final List<(String, bool)> photoLoads = [];
  List<ProfileCard> requests = [];
  List<ProfileCard> viewers = [];
  final calls = <String>[];

  @override
  Future<ListingStatus> syncListing(String uid) async {
    syncs++;
    if (failSync) throw const DiscoveryException();
    return status;
  }

  DiscoverFeed? lastFeed;
  DiscoveryFilter? preferences;
  bool failPreferences = false;

  /// Newest members first in "New members"; tests list cards oldest first.
  @override
  Future<DiscoveryPage> browse(
    String uid,
    DiscoveryFilter filter, {
    Object? after,
    DiscoverFeed feed = DiscoverFeed.forYou,
  }) async {
    lastFilter = filter;
    lastFeed = feed;
    if (failBrowse) throw const DiscoveryException();
    if (feed == DiscoverFeed.newMembers) {
      return DiscoveryPage(cards.reversed.toList());
    }
    final today = DateTime(2026, 9, 29);
    return DiscoveryPage(
      cards
          .where(
            (c) =>
                filter.matches(c, today) &&
                (filter.countries.isEmpty ||
                    filter.countries.contains(c.profile.residenceCountry)),
          )
          .toList(),
    );
  }

  @override
  Future<DiscoveryFilter?> loadPreferences(String uid) async => preferences;

  @override
  Future<void> savePreferences(String uid, DiscoveryFilter value) async {
    if (failPreferences) throw const DiscoveryException();
    preferences = value;
  }

  @override
  Future<Uint8List> photo(
    String ownerUid,
    String photoId, {
    bool blurred = false,
  }) async {
    photoLoads.add((ownerUid, blurred));
    return png;
  }

  @override
  Future<PhotoAccess> photoAccess(String viewerUid, String ownerUid) async =>
      access[ownerUid] ?? PhotoAccess.none;

  @override
  Future<void> requestPhotos(String viewerUid, String ownerUid) async {
    if (failRequest) throw const DiscoveryException();
    access[ownerUid] = PhotoAccess.requested;
  }

  @override
  Future<void> cancelRequest(String viewerUid, String ownerUid) async {
    access.remove(ownerUid);
  }

  @override
  Future<List<ProfileCard>> photoRequests(String ownerUid) async => requests;

  @override
  Future<List<ProfileCard>> photoViewers(String ownerUid) async => viewers;

  @override
  Future<void> approve(String ownerUid, String viewerUid) async {
    calls.add('approve $viewerUid');
    final card = requests.firstWhere((c) => c.uid == viewerUid);
    requests = [...requests]..remove(card);
    viewers = [...viewers, card];
  }

  @override
  Future<void> decline(String ownerUid, String viewerUid) async {
    calls.add('decline $viewerUid');
    requests = requests.where((c) => c.uid != viewerUid).toList();
  }

  @override
  Future<void> revoke(String ownerUid, String viewerUid) async {
    calls.add('revoke $viewerUid');
    viewers = viewers.where((c) => c.uid != viewerUid).toList();
  }
}
