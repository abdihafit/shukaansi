import '../data/countries.dart';

enum ProfileGender { male, female }

enum MaritalStatus { neverMarried, divorced, widowed }

enum Ethnicity { somali, arab, other }

enum Profession {
  accountant,
  architect,
  bankingFinance,
  businessOwner,
  chef,
  civilServant,
  constructionTrades,
  customerService,
  dentist,
  designerCreative,
  doctor,
  driverTransport,
  electrician,
  engineer,
  farmerAgriculture,
  healthcareAssistant,
  homemaker,
  hospitality,
  humanResources,
  imamIslamicScholar,
  itSoftware,
  journalistMedia,
  lawyer,
  lecturer,
  logistics,
  marketingSales,
  mechanic,
  militaryDefence,
  ngoHumanitarian,
  nurse,
  pharmacist,
  pilotAviation,
  policeSecurity,
  projectManager,
  psychologistCounsellor,
  realEstate,
  researcherScientist,
  retail,
  socialWorker,
  student,
  teacher,
  translatorInterpreter,
  lookingForWork,
  retired,
  other,
}

enum EducationLevel {
  secondary,
  diploma,
  bachelors,
  masters,
  doctorate,
  islamicStudies,
  other,
}

enum PracticeLevel { strict, active, growing, cultural }

enum MarriageTimeline { soon, withinYear, oneToTwoYears, moreThanTwoYears }

enum Relocation { yes, open, no }

const profileSchemaVersion = 2;

/// Profile information intended for future introductions. No email, phone,
/// birth date, tokens or privileges; those stay private or in Firebase Auth.
class MatrimonialProfile {
  const MatrimonialProfile({
    required this.name,
    required this.gender,
    required this.nationality,
    required this.residenceCountry,
    required this.city,
    required this.ethnicity,
    this.ethnicityOther = '',
    required this.profession,
    this.professionOther = '',
    required this.education,
    required this.practice,
    required this.marriageTimeline,
    required this.relocation,
    required this.maritalStatus,
    required this.about,
  });
  final String name;
  final ProfileGender gender;
  final String nationality;
  final String residenceCountry;
  final String city;
  final Ethnicity ethnicity;
  final String ethnicityOther;
  final Profession profession;
  final String professionOther;
  final EducationLevel education;
  final PracticeLevel practice;
  final MarriageTimeline marriageTimeline;
  final Relocation relocation;
  final MaritalStatus maritalStatus;
  final String about;

  static bool validText(String value, int min, int max) =>
      value == value.trim() && value.length >= min && value.length <= max;

  /// "Other" answers need a short description; any other answer must not carry one.
  static bool validOther(bool isOther, String value) =>
      isOther ? validText(value, 2, 40) : value.isEmpty;

  bool get isValid =>
      validText(name, 2, 50) &&
      Countries.isValid(nationality) &&
      Countries.isValid(residenceCountry) &&
      validText(city, 2, 56) &&
      validOther(ethnicity == Ethnicity.other, ethnicityOther) &&
      validOther(profession == Profession.other, professionOther) &&
      validText(about, 20, 500);

  Map<String, Object> toMap() => {
    'schemaVersion': profileSchemaVersion,
    'name': name,
    'gender': gender.name,
    'nationality': nationality,
    'residenceCountry': residenceCountry,
    'city': city,
    'ethnicity': ethnicity.name,
    'ethnicityOther': ethnicityOther,
    'profession': profession.name,
    'professionOther': professionOther,
    'education': education.name,
    'practice': practice.name,
    'marriageTimeline': marriageTimeline.name,
    'relocation': relocation.name,
    'maritalStatus': maritalStatus.name,
    'about': about,
    'onboardingComplete': true,
  };

  factory MatrimonialProfile.fromMap(Map<String, dynamic> data) {
    if (data['schemaVersion'] != profileSchemaVersion ||
        data['onboardingComplete'] != true) {
      throw const FormatException('Unsupported profile');
    }
    final profile = MatrimonialProfile(
      name: data['name'] as String,
      gender: ProfileGender.values.byName(data['gender'] as String),
      nationality: data['nationality'] as String,
      residenceCountry: data['residenceCountry'] as String,
      city: data['city'] as String,
      ethnicity: Ethnicity.values.byName(data['ethnicity'] as String),
      ethnicityOther: data['ethnicityOther'] as String,
      profession: Profession.values.byName(data['profession'] as String),
      professionOther: data['professionOther'] as String,
      education: EducationLevel.values.byName(data['education'] as String),
      practice: PracticeLevel.values.byName(data['practice'] as String),
      marriageTimeline: MarriageTimeline.values.byName(
        data['marriageTimeline'] as String,
      ),
      relocation: Relocation.values.byName(data['relocation'] as String),
      maritalStatus: MaritalStatus.values.byName(
        data['maritalStatus'] as String,
      ),
      about: data['about'] as String,
    );
    if (!profile.isValid) throw const FormatException('Invalid profile');
    return profile;
  }
}

/// Owner-only details: never part of the profile shown to others.
class PrivateDetails {
  const PrivateDetails({
    required this.birthDate,
    required this.phoneCountry,
    required this.phoneNumber,
  });

  /// Date of birth as a UTC calendar date (midnight).
  final DateTime birthDate;
  final String phoneCountry;

  /// E.164, for example +252612345678.
  final String phoneNumber;

  static final _e164 = RegExp(r'^\+[1-9][0-9]{6,14}$');

  /// Countries whose international format keeps the leading zero.
  static const _keepsLeadingZero = {'IT', 'SM', 'VA'};

  static DateTime dateOnly(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  /// Eligible from the day after the 18th birthday, so a user in any time
  /// zone also satisfies the server rule that compares against UTC time.
  static bool isAdult(DateTime birthDate, DateTime today) {
    final eligible = DateTime.utc(
      birthDate.year + 18,
      birthDate.month,
      birthDate.day + 1,
    );
    return !eligible.isAfter(dateOnly(today)) &&
        birthDate.year >= dateOnly(today).year - 100;
  }

  /// Converts a locally typed number to E.164, or null if it cannot be valid.
  static String? toE164(String countryCode, String national) {
    final country = Countries.byCode(countryCode);
    if (country == null) return null;
    var digits = national.replaceAll(RegExp(r'[\s\-().]'), '');
    if (!RegExp(r'^[0-9]{4,14}$').hasMatch(digits)) return null;
    if (digits.startsWith('0') && !_keepsLeadingZero.contains(countryCode)) {
      digits = digits.substring(1);
    }
    final number = '+${country.dialCode}$digits';
    return _e164.hasMatch(number) ? number : null;
  }

  bool isValid(DateTime today) =>
      birthDate == dateOnly(birthDate) &&
      isAdult(birthDate, today) &&
      Countries.isValid(phoneCountry) &&
      _e164.hasMatch(phoneNumber) &&
      phoneNumber.startsWith('+${Countries.byCode(phoneCountry)!.dialCode}');

  /// The national part of [phoneNumber], for pre-filling the phone field.
  String get nationalNumber => phoneNumber.substring(
    '+${Countries.byCode(phoneCountry)!.dialCode}'.length,
  );
}

/// Answers from a schema v1 profile that carry over into the v2 questions.
class LegacyProfile {
  const LegacyProfile({
    required this.name,
    required this.gender,
    required this.city,
    required this.maritalStatus,
    required this.about,
  });
  final String? name;
  final ProfileGender? gender;
  final String? city;
  final MaritalStatus? maritalStatus;
  final String? about;

  factory LegacyProfile.fromMap(Map<String, dynamic> data) {
    T? pick<T extends Enum>(List<T> values, Object? raw) =>
        values.where((v) => v.name == raw).firstOrNull;
    String? text(Object? raw, int min, int max) =>
        raw is String && MatrimonialProfile.validText(raw, min, max)
        ? raw
        : null;
    return LegacyProfile(
      name: text(data['name'], 2, 50),
      gender: pick(ProfileGender.values, data['gender']),
      city: text(data['city'], 2, 56),
      maritalStatus: pick(MaritalStatus.values, data['maritalStatus']),
      about: text(data['about'], 20, 500),
    );
  }
}
