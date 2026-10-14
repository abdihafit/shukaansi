import 'package:flutter/widgets.dart';

import '../data/countries.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/matrimonial_profile.dart';

String genderLabel(AppLocalizations s, ProfileGender value) =>
    value == ProfileGender.male ? s.profileMale : s.profileFemale;

String maritalLabel(AppLocalizations s, MaritalStatus value) => switch (value) {
  MaritalStatus.neverMarried => s.profileNeverMarried,
  MaritalStatus.divorced => s.profileDivorced,
  MaritalStatus.widowed => s.profileWidowed,
};

String ethnicityLabel(AppLocalizations s, Ethnicity value) => switch (value) {
  Ethnicity.somali => s.ethnicitySomali,
  Ethnicity.arab => s.ethnicityArab,
  Ethnicity.other => s.ethnicityOther,
};

String practiceLabel(AppLocalizations s, PracticeLevel value) =>
    switch (value) {
      PracticeLevel.strict => s.practiceStrict,
      PracticeLevel.active => s.practiceActive,
      PracticeLevel.growing => s.practiceGrowing,
      PracticeLevel.cultural => s.practiceCultural,
    };

String practiceInfo(AppLocalizations s, PracticeLevel value) => switch (value) {
  PracticeLevel.strict => s.practiceStrictInfo,
  PracticeLevel.active => s.practiceActiveInfo,
  PracticeLevel.growing => s.practiceGrowingInfo,
  PracticeLevel.cultural => s.practiceCulturalInfo,
};

String timelineLabel(AppLocalizations s, MarriageTimeline value) =>
    switch (value) {
      MarriageTimeline.soon => s.timelineSoon,
      MarriageTimeline.withinYear => s.timelineWithinYear,
      MarriageTimeline.oneToTwoYears => s.timelineOneToTwoYears,
      MarriageTimeline.moreThanTwoYears => s.timelineMoreThanTwoYears,
    };

String relocationLabel(AppLocalizations s, Relocation value) => switch (value) {
  Relocation.yes => s.relocationYes,
  Relocation.open => s.relocationOpen,
  Relocation.no => s.relocationNo,
};

String educationLabel(AppLocalizations s, EducationLevel value) =>
    switch (value) {
      EducationLevel.secondary => s.educationSecondary,
      EducationLevel.diploma => s.educationDiploma,
      EducationLevel.bachelors => s.educationBachelors,
      EducationLevel.masters => s.educationMasters,
      EducationLevel.doctorate => s.educationDoctorate,
      EducationLevel.islamicStudies => s.educationIslamicStudies,
      EducationLevel.other => s.optionOther,
    };

String professionLabel(AppLocalizations s, Profession value) => switch (value) {
  Profession.accountant => s.professionAccountant,
  Profession.architect => s.professionArchitect,
  Profession.bankingFinance => s.professionBankingFinance,
  Profession.businessOwner => s.professionBusinessOwner,
  Profession.chef => s.professionChef,
  Profession.civilServant => s.professionCivilServant,
  Profession.constructionTrades => s.professionConstructionTrades,
  Profession.customerService => s.professionCustomerService,
  Profession.dentist => s.professionDentist,
  Profession.designerCreative => s.professionDesignerCreative,
  Profession.doctor => s.professionDoctor,
  Profession.driverTransport => s.professionDriverTransport,
  Profession.electrician => s.professionElectrician,
  Profession.engineer => s.professionEngineer,
  Profession.farmerAgriculture => s.professionFarmerAgriculture,
  Profession.healthcareAssistant => s.professionHealthcareAssistant,
  Profession.homemaker => s.professionHomemaker,
  Profession.hospitality => s.professionHospitality,
  Profession.humanResources => s.professionHumanResources,
  Profession.imamIslamicScholar => s.professionImamIslamicScholar,
  Profession.itSoftware => s.professionItSoftware,
  Profession.journalistMedia => s.professionJournalistMedia,
  Profession.lawyer => s.professionLawyer,
  Profession.lecturer => s.professionLecturer,
  Profession.logistics => s.professionLogistics,
  Profession.marketingSales => s.professionMarketingSales,
  Profession.mechanic => s.professionMechanic,
  Profession.militaryDefence => s.professionMilitaryDefence,
  Profession.ngoHumanitarian => s.professionNgoHumanitarian,
  Profession.nurse => s.professionNurse,
  Profession.pharmacist => s.professionPharmacist,
  Profession.pilotAviation => s.professionPilotAviation,
  Profession.policeSecurity => s.professionPoliceSecurity,
  Profession.projectManager => s.professionProjectManager,
  Profession.psychologistCounsellor => s.professionPsychologistCounsellor,
  Profession.realEstate => s.professionRealEstate,
  Profession.researcherScientist => s.professionResearcherScientist,
  Profession.retail => s.professionRetail,
  Profession.socialWorker => s.professionSocialWorker,
  Profession.student => s.professionStudent,
  Profession.teacher => s.professionTeacher,
  Profession.translatorInterpreter => s.professionTranslatorInterpreter,
  Profession.lookingForWork => s.professionLookingForWork,
  Profession.retired => s.professionRetired,
  Profession.other => s.optionOther,
};

/// Country name in the app language (CLDR English or Somali).
String countryName(BuildContext context, String code) =>
    Countries.byCode(code)
        ?.name(Localizations.localeOf(context).languageCode) ??
    code;

/// A person's name for display in Title Case ("abdihafit ISMAIL" ->
/// "Abdihafit Ismail"), including after hyphens and apostrophes. Only how it
/// is shown changes; what is stored stays as the member typed it.
String displayName(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .map(
      (word) => word.splitMapJoin(
        RegExp(r"[-']"),
        onNonMatch: (part) => part.isEmpty
            ? part
            : part[0].toUpperCase() + part.substring(1).toLowerCase(),
      ),
    )
    .join(' ');
