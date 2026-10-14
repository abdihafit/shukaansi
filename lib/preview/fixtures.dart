import 'package:flutter/foundation.dart';

import '../models/discovery.dart';
import '../models/matrimonial_profile.dart';
import '../models/membership.dart';
import '../models/wali.dart';
import '../redesign/member_profile_view.dart';
import 'synthetic_photos.dart';

/// Fictional people for the development preview. None of them exist; all
/// photos are synthetic drawings. Nothing here is ever sent to a backend.
const previewViewerUid = 'preview-viewer';

enum PreviewScenario {
  populated,
  preferencesNotSet,
  noMatches,
  loading,
  networkError,
  incompleteProfile,
  awaitingReview,
  emptyActivity,
}

class PreviewMember {
  const PreviewMember({
    required this.card,
    required this.palette,
    this.plan = MembershipPlan.free,
    this.concept = const ProfileConcept(),
  });
  final ProfileCard card;
  final List<PortraitSpec> palette;
  final MembershipPlan plan;

  /// Proposed content not in the data model (concept preview only).
  final ProfileConcept concept;
  String get uid => card.uid;
}

PortraitSpec _spec(
  int bg,
  int arch,
  int cloth,
  int skin, {
  bool square = false,
}) => PortraitSpec(
  background: bg,
  arch: arch,
  cloth: cloth,
  skin: skin,
  covered: true,
  width: square ? 420 : 360,
  height: square ? 420 : 450,
);

PreviewMember _member({
  required String uid,
  required String name,
  required int birthYearMonth,
  required String country,
  required String city,
  required Profession profession,
  required EducationLevel education,
  required PracticeLevel practice,
  required MaritalStatus marital,
  required MarriageTimeline timeline,
  required Relocation relocation,
  required String about,
  required int skin,
  required List<int> cloths,
  bool verified = true,
  bool blurred = false,
  MembershipPlan plan = MembershipPlan.free,
  List<ProfilePrompt> prompts = const [],
  List<String> interests = const [],
}) => PreviewMember(
  plan: plan,
  concept: ProfileConcept(prompts: prompts, interests: interests),
  palette: [
    _spec(0xF1ECE2, 0xE3D8C3, cloths[0], skin),
    _spec(0xE7EFEA, 0xD3E2D9, cloths[1], skin, square: true),
    _spec(0xF3E9E4, 0xE6D3C9, cloths[2], skin),
  ],
  card: ProfileCard(
    uid: uid,
    profile: MatrimonialProfile(
      name: name,
      gender: ProfileGender.female,
      nationality: 'SO',
      residenceCountry: country,
      city: city,
      ethnicity: Ethnicity.somali,
      profession: profession,
      education: education,
      practice: practice,
      marriageTimeline: timeline,
      relocation: relocation,
      maritalStatus: marital,
      about: about,
    ),
    birthYearMonth: birthYearMonth,
    photoIds: ['$uid-1', '$uid-2', '$uid-3'],
    photosBlurred: blurred,
    verified: verified,
  ),
);

final previewMembers = <PreviewMember>[
  _member(
    uid: 'fardowsa',
    name: 'Fardowsa',
    birthYearMonth: 199803,
    country: 'AE',
    city: 'Dubai',
    profession: Profession.bankingFinance,
    education: EducationLevel.masters,
    practice: PracticeLevel.active,
    marital: MaritalStatus.neverMarried,
    timeline: MarriageTimeline.withinYear,
    relocation: Relocation.open,
    about:
        'I work in Islamic finance and love what I do. I grew up between '
        'Hargeisa and Dubai, so I am at home in both worlds. Looking for a '
        'husband who is steady in his deen, close to his family and ready to '
        'build something lasting together.',
    skin: 0x8D5A3B,
    cloths: [0x0E4A43, 0x6B2D3A, 0x23395B],
    prompts: const [
      ProfilePrompt(
        'The quickest way to my heart',
        'Remembering how my mum takes her shaah.',
      ),
      ProfilePrompt(
        'Together we could',
        'Plan a family trip back to Somaliland.',
      ),
    ],
    interests: const ['Reading', 'Calligraphy', 'Travel', 'Swimming'],
  ),
  _member(
    uid: 'sagal',
    name: 'Sagal',
    birthYearMonth: 199705,
    country: 'CA',
    city: 'Toronto',
    profession: Profession.engineer,
    education: EducationLevel.masters,
    practice: PracticeLevel.active,
    marital: MaritalStatus.neverMarried,
    timeline: MarriageTimeline.withinYear,
    relocation: Relocation.open,
    about:
        'Civil engineer, eldest of five, and the family\'s unofficial event '
        'planner. I value a calm home, honest conversations and a husband '
        'who prays and keeps his promises.',
    skin: 0x6E4329,
    cloths: [0x7A5C1E, 0x1F4E5F, 0x5A2E4A],
    verified: false,
    plan: MembershipPlan.premium,
    prompts: const [
      ProfilePrompt(
        'A value I will not compromise on',
        'Honesty, even when it is hard.',
      ),
    ],
    interests: const ['Hiking', 'Cooking', 'Volunteering'],
  ),
  _member(
    uid: 'hibo',
    name: 'Hibo',
    birthYearMonth: 199302,
    country: 'US',
    city: 'Columbus',
    profession: Profession.doctor,
    education: EducationLevel.doctorate,
    practice: PracticeLevel.active,
    marital: MaritalStatus.widowed,
    timeline: MarriageTimeline.withinYear,
    relocation: Relocation.no,
    about:
        'Family doctor in Columbus. After losing my husband I took time to '
        'heal, alhamdulillah. I am ready to marry again and hope to meet a '
        'patient, grounded man who wants a faith-centred home.',
    skin: 0x5B3622,
    cloths: [0x2F3B2F, 0x4B2E2A, 0x2C3E50],
    blurred: true,
  ),
  _member(
    uid: 'ladan',
    name: 'Ladan',
    birthYearMonth: 200004,
    country: 'AU',
    city: 'Melbourne',
    profession: Profession.designerCreative,
    education: EducationLevel.bachelors,
    practice: PracticeLevel.growing,
    marital: MaritalStatus.neverMarried,
    timeline: MarriageTimeline.oneToTwoYears,
    relocation: Relocation.yes,
    about:
        'Product designer who sketches on every napkin. Learning more about '
        'my deen each year and looking for someone to grow with, kindly and '
        'patiently.',
    skin: 0x9A6444,
    cloths: [0xB07A2A, 0x3D5A80, 0x7B3F61],
    interests: const ['Design', 'Coffee', 'Poetry'],
  ),
  _member(
    uid: 'amina',
    name: 'Amina',
    birthYearMonth: 199901,
    country: 'GB',
    city: 'London',
    profession: Profession.nurse,
    education: EducationLevel.bachelors,
    practice: PracticeLevel.active,
    marital: MaritalStatus.neverMarried,
    timeline: MarriageTimeline.withinYear,
    relocation: Relocation.open,
    about:
        'Paediatric nurse in East London. Sundays are for my mum\'s kitchen '
        'and long walks by the river. Looking for a kind, practising husband '
        'who laughs easily.',
    skin: 0x7B4B2E,
    cloths: [0x0F5546, 0x8C3B3B, 0x2B4C7E],
  ),
  _member(
    uid: 'hodan',
    name: 'Hodan',
    birthYearMonth: 200103,
    country: 'US',
    city: 'Minneapolis',
    profession: Profession.teacher,
    education: EducationLevel.bachelors,
    practice: PracticeLevel.active,
    marital: MaritalStatus.neverMarried,
    timeline: MarriageTimeline.oneToTwoYears,
    relocation: Relocation.no,
    about:
        'Primary school teacher and Qur\'an class volunteer. I want my '
        'family close by, so I hope to stay in Minnesota, insha\'Allah.',
    skin: 0x83512F,
    cloths: [0x5E3A6E, 0x1E5C4E, 0x8A5A2B],
  ),
  _member(
    uid: 'nasra',
    name: 'Nasra',
    birthYearMonth: 199504,
    country: 'NO',
    city: 'Oslo',
    profession: Profession.psychologistCounsellor,
    education: EducationLevel.masters,
    practice: PracticeLevel.strict,
    marital: MaritalStatus.divorced,
    timeline: MarriageTimeline.soon,
    relocation: Relocation.open,
    about:
        'Family counsellor in Oslo. My faith keeps me grounded and my work '
        'taught me how much good communication matters. Ready to marry soon, '
        'with my family involved from the start.',
    skin: 0x6A3F27,
    cloths: [0x1B3A4B, 0x5C4033, 0x2E5E4E],
    plan: MembershipPlan.premium,
  ),
  _member(
    uid: 'ifrah',
    name: 'Ifrah',
    birthYearMonth: 200204,
    country: 'KE',
    city: 'Nairobi',
    profession: Profession.student,
    education: EducationLevel.bachelors,
    practice: PracticeLevel.growing,
    marital: MaritalStatus.neverMarried,
    timeline: MarriageTimeline.withinYear,
    relocation: Relocation.yes,
    about:
        'Final-year pharmacy student in Nairobi. Big family, bigger dreams. '
        'Open to moving for the right person and his family.',
    skin: 0x744629,
    cloths: [0x2A6F62, 0x9B4D3A, 0x3E4A7A],
  ),
];

PreviewMember? previewMember(String uid) =>
    previewMembers.where((m) => m.uid == uid).firstOrNull;

const previewViewer = MatrimonialProfile(
  name: 'Yusuf',
  gender: ProfileGender.male,
  nationality: 'SO',
  residenceCountry: 'GB',
  city: 'London',
  ethnicity: Ethnicity.somali,
  profession: Profession.itSoftware,
  education: EducationLevel.bachelors,
  practice: PracticeLevel.active,
  marriageTimeline: MarriageTimeline.withinYear,
  relocation: Relocation.open,
  maritalStatus: MaritalStatus.neverMarried,
  about:
      'Software developer in London, eldest son, football on Saturdays. '
      'Looking for a practising, kind-hearted wife to build a calm home with.',
);

final previewViewerDetails = PrivateDetails(
  birthDate: DateTime.utc(1995, 3, 12),
  phoneCountry: 'GB',
  phoneNumber: '+447700900000',
);

const viewerPhotoSpecs = {
  'me-1': PortraitSpec(
    background: 0xEAE6DC,
    arch: 0xD8CFBC,
    cloth: 0x1F3B5A,
    skin: 0x7A4A2C,
  ),
  'me-2': PortraitSpec(
    background: 0xE4ECE6,
    arch: 0xCFDDD3,
    cloth: 0x0E4A43,
    skin: 0x7A4A2C,
  ),
};

/// Sample conversations: (from, text, minutes ago).
final previewThreads = <String, List<(String, String, int)>>{
  'amina': [
    (
      previewViewerUid,
      'Assalamu alaikum Amina, I enjoyed reading your profile.',
      300,
    ),
    (
      'amina',
      'Wa alaikum assalam Yusuf! JazakAllahu khayran. Your note about volunteering stood out.',
      290,
    ),
    (previewViewerUid, 'Do you still volunteer with the food bank?', 120),
    (
      'amina',
      'Every Saturday, alhamdulillah. My uncle would like to speak with your family next week.',
      95,
    ),
  ],
  'nasra': [
    (
      'nasra',
      'Assalamu alaikum. My Wali approved our match, alhamdulillah. What are you hoping for in the next year?',
      12,
    ),
  ],
};

/// Simulated replies after you send a message (clearly part of the preview).
const previewReplies = [
  'Wa alaikum assalam, JazakAllahu khayran for your message.',
  'That sounds good, insha\'Allah. I will share it with my family.',
  'I appreciate that. What matters most to you in a home?',
];

/// Everything the preview can change while running, in memory only.
class PreviewWorld extends ChangeNotifier {
  PreviewScenario scenario = PreviewScenario.populated;
  MembershipPlan viewerPlan = MembershipPlan.free;

  /// Bumped to rebuild the preview from scratch when the scenario changes.
  int revision = 0;

  void setScenario(PreviewScenario value) {
    scenario = value;
    revision++;
    notifyListeners();
  }

  void setPremium(bool premium) {
    viewerPlan = premium ? MembershipPlan.premium : MembershipPlan.free;
    notifyListeners();
  }

  bool get activityEmpty => scenario == PreviewScenario.emptyActivity;

  /// Guardian decisions held by the sisters' Walis (sisters always need one).
  Map<String, WaliDecision> walisFor() => activityEmpty
      ? {}
      : {
          'amina': WaliDecision.approved,
          'nasra': WaliDecision.approved,
          'hodan': WaliDecision.pending,
        };
}
