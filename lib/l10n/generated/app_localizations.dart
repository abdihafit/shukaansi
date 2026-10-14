import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_so.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('so'),
  ];

  /// No description provided for @authLoading.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get authLoading;

  /// No description provided for @authRejected.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete this request. Check your details and try again.'**
  String get authRejected;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Connection unavailable. Check your internet and try again.'**
  String get authNetworkError;

  /// No description provided for @authThrottled.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait before trying again.'**
  String get authThrottled;

  /// No description provided for @authUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authUnknownError;

  /// No description provided for @authRequestCompleted.
  ///
  /// In en, this message translates to:
  /// **'Account request completed.'**
  String get authRequestCompleted;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Shukaansi'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Halal • Serious • Together'**
  String get tagline;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @chooseLanguageSomali.
  ///
  /// In en, this message translates to:
  /// **'Dooro luqaddaada'**
  String get chooseLanguageSomali;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @somaliLanguage.
  ///
  /// In en, this message translates to:
  /// **'Soomaali'**
  String get somaliLanguage;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum, welcome to Shukaansi'**
  String get welcomeTitle;

  /// No description provided for @selectedLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language selected: English'**
  String get selectedLanguage;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @authIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Your next step toward marriage'**
  String get authIntroduction;

  /// No description provided for @authPreviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Account services are not available yet. These forms do not create an account or sign you in.'**
  String get authPreviewNotice;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account services are unavailable. Please try again later.'**
  String get authUnavailable;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @passwordGuidance.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get passwordGuidance;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @needAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Shukaansi? Create an account'**
  String get needAccount;

  /// No description provided for @sessionFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to check your session.'**
  String get sessionFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @accountSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You are signed in'**
  String get accountSignedIn;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign out. Please try again.'**
  String get signOutFailed;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @accountStageNotice.
  ///
  /// In en, this message translates to:
  /// **'Your account session is active. Profiles and introductions are not available yet. Signing in does not verify your identity.'**
  String get accountStageNotice;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordIntroduction;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @resetPasswordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'If an account can receive a reset email at this address, a link will be sent. Check your inbox and spam folder, then return to sign in. The email may be in English.'**
  String get resetPasswordConfirmation;

  /// No description provided for @profileAboutHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what matters to you in marriage. Do not include contact details or sensitive private information.'**
  String get profileAboutHint;

  /// No description provided for @profileAdultDeclaration.
  ///
  /// In en, this message translates to:
  /// **'I confirm that I am 18 or older.'**
  String get profileAdultDeclaration;

  /// No description provided for @profileFemale.
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get profileFemale;

  /// No description provided for @profileTextLength.
  ///
  /// In en, this message translates to:
  /// **'Enter between {min} and {max} characters.'**
  String profileTextLength(int min, int max);

  /// No description provided for @profileLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking your profile'**
  String get profileLoading;

  /// No description provided for @profileDivorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get profileDivorced;

  /// No description provided for @profileLocationNotice.
  ///
  /// In en, this message translates to:
  /// **'Enter your city only, not your street address.'**
  String get profileLocationNotice;

  /// No description provided for @profileReview.
  ///
  /// In en, this message translates to:
  /// **'Review your profile'**
  String get profileReview;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get profileSave;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your profile could not be saved. Your entries are still here. Check your connection and try again.'**
  String get profileSaveFailed;

  /// No description provided for @profileWidowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get profileWidowed;

  /// No description provided for @profileMaritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital status'**
  String get profileMaritalStatus;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About you and your marriage intentions'**
  String get profileAbout;

  /// No description provided for @profileStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String profileStep(int current, int total);

  /// No description provided for @profileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCity;

  /// No description provided for @profileNeverMarried.
  ///
  /// In en, this message translates to:
  /// **'Never married'**
  String get profileNeverMarried;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get profileBack;

  /// No description provided for @profilePrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Build a respectful introduction. Your profile is private to you at this stage.'**
  String get profilePrivacyNotice;

  /// No description provided for @profileAdultRequired.
  ///
  /// In en, this message translates to:
  /// **'You must be 18 or older to create a Shukaansi profile.'**
  String get profileAdultRequired;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get profileName;

  /// No description provided for @profileCreated.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah, your profile is saved'**
  String get profileCreated;

  /// No description provided for @profileContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileContinue;

  /// No description provided for @profileMale.
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get profileMale;

  /// No description provided for @profileCreatedNotice.
  ///
  /// In en, this message translates to:
  /// **'Only you can view this profile for now. Introductions are not available yet. This does not verify your identity.'**
  String get profileCreatedNotice;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your profile could not be loaded. Check your connection and try again. Profile services may not be available yet.'**
  String get profileLoadFailed;

  /// No description provided for @profileStepBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start with you'**
  String get profileStepBasicsTitle;

  /// No description provided for @profileStepBasicsHint.
  ///
  /// In en, this message translates to:
  /// **'The essentials every introduction begins with.'**
  String get profileStepBasicsHint;

  /// No description provided for @profileStepRootsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your roots'**
  String get profileStepRootsTitle;

  /// No description provided for @profileStepRootsHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us where your family story begins.'**
  String get profileStepRootsHint;

  /// No description provided for @profileStepHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Where you live today'**
  String get profileStepHomeTitle;

  /// No description provided for @profileStepPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone number'**
  String get profileStepPhoneTitle;

  /// No description provided for @profileStepPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Private to you. It is never shown on your profile.'**
  String get profileStepPhoneHint;

  /// No description provided for @profileStepWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Work and study'**
  String get profileStepWorkTitle;

  /// No description provided for @profileStepWorkHint.
  ///
  /// In en, this message translates to:
  /// **'Share what you do and how far you have studied.'**
  String get profileStepWorkHint;

  /// No description provided for @profileStepFaithTitle.
  ///
  /// In en, this message translates to:
  /// **'Faith and family'**
  String get profileStepFaithTitle;

  /// No description provided for @profileStepFaithHint.
  ///
  /// In en, this message translates to:
  /// **'There is no wrong answer. Honest answers help the right person find you.'**
  String get profileStepFaithHint;

  /// No description provided for @profileStepIntentionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your marriage intentions'**
  String get profileStepIntentionsTitle;

  /// No description provided for @profileStepIntentionsHint.
  ///
  /// In en, this message translates to:
  /// **'Clear intentions make for respectful introductions.'**
  String get profileStepIntentionsHint;

  /// No description provided for @profileStepAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'In your own words'**
  String get profileStepAboutTitle;

  /// No description provided for @profileStepReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Check your answers before saving.'**
  String get profileStepReviewHint;

  /// No description provided for @profileUpdateNotice.
  ///
  /// In en, this message translates to:
  /// **'We have added new questions. Your earlier answers are already filled in.'**
  String get profileUpdateNotice;

  /// No description provided for @profileUpdateSave.
  ///
  /// In en, this message translates to:
  /// **'Update profile'**
  String get profileUpdateSave;

  /// No description provided for @profileDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileDateOfBirth;

  /// No description provided for @profileDateOfBirthHint.
  ///
  /// In en, this message translates to:
  /// **'Private. Used to confirm you are 18 or older.'**
  String get profileDateOfBirthHint;

  /// No description provided for @profileSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get profileSelectDate;

  /// No description provided for @profileNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get profileNationality;

  /// No description provided for @profileResidence.
  ///
  /// In en, this message translates to:
  /// **'Country you live in'**
  String get profileResidence;

  /// No description provided for @profileEthnicity.
  ///
  /// In en, this message translates to:
  /// **'Ethnicity'**
  String get profileEthnicity;

  /// No description provided for @profileEthnicityOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Your ethnicity'**
  String get profileEthnicityOtherLabel;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get profilePhone;

  /// No description provided for @profileCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get profileCountryCode;

  /// No description provided for @profilePhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number without the country code.'**
  String get profilePhoneInvalid;

  /// No description provided for @profileProfession.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get profileProfession;

  /// No description provided for @profileProfessionOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Your profession'**
  String get profileProfessionOtherLabel;

  /// No description provided for @profileEducation.
  ///
  /// In en, this message translates to:
  /// **'Highest education'**
  String get profileEducation;

  /// No description provided for @profilePractice.
  ///
  /// In en, this message translates to:
  /// **'Your religious practice'**
  String get profilePractice;

  /// No description provided for @profileTimeline.
  ///
  /// In en, this message translates to:
  /// **'When do you hope to marry?'**
  String get profileTimeline;

  /// No description provided for @profileRelocation.
  ///
  /// In en, this message translates to:
  /// **'Open to moving for marriage?'**
  String get profileRelocation;

  /// No description provided for @profileSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get profileSearch;

  /// No description provided for @profileSuggested.
  ///
  /// In en, this message translates to:
  /// **'Common choices'**
  String get profileSuggested;

  /// No description provided for @profileAllOptions.
  ///
  /// In en, this message translates to:
  /// **'All options'**
  String get profileAllOptions;

  /// No description provided for @profileNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get profileNoResults;

  /// No description provided for @profileSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get profileSelect;

  /// No description provided for @profileSectionPublic.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileSectionPublic;

  /// No description provided for @profileSectionPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private to you'**
  String get profileSectionPrivate;

  /// No description provided for @profileSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get profileSelected;

  /// No description provided for @ethnicitySomali.
  ///
  /// In en, this message translates to:
  /// **'Somali Muslim'**
  String get ethnicitySomali;

  /// No description provided for @ethnicityArab.
  ///
  /// In en, this message translates to:
  /// **'Arab Muslim'**
  String get ethnicityArab;

  /// No description provided for @ethnicityOther.
  ///
  /// In en, this message translates to:
  /// **'Other Muslim background'**
  String get ethnicityOther;

  /// No description provided for @practiceStrict.
  ///
  /// In en, this message translates to:
  /// **'Very practising'**
  String get practiceStrict;

  /// No description provided for @practiceStrictInfo.
  ///
  /// In en, this message translates to:
  /// **'Prayer, fasting and Islamic guidance shape my daily life.'**
  String get practiceStrictInfo;

  /// No description provided for @practiceActive.
  ///
  /// In en, this message translates to:
  /// **'Practising'**
  String get practiceActive;

  /// No description provided for @practiceActiveInfo.
  ///
  /// In en, this message translates to:
  /// **'I make regular practice part of my routine where I can.'**
  String get practiceActiveInfo;

  /// No description provided for @practiceGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing in faith'**
  String get practiceGrowing;

  /// No description provided for @practiceGrowingInfo.
  ///
  /// In en, this message translates to:
  /// **'I am learning and working on becoming more consistent.'**
  String get practiceGrowingInfo;

  /// No description provided for @practiceCultural.
  ///
  /// In en, this message translates to:
  /// **'Culturally Muslim'**
  String get practiceCultural;

  /// No description provided for @practiceCulturalInfo.
  ///
  /// In en, this message translates to:
  /// **'Islam is part of my identity, though I practise less often.'**
  String get practiceCulturalInfo;

  /// No description provided for @timelineSoon.
  ///
  /// In en, this message translates to:
  /// **'As soon as the right person comes'**
  String get timelineSoon;

  /// No description provided for @timelineWithinYear.
  ///
  /// In en, this message translates to:
  /// **'Within a year'**
  String get timelineWithinYear;

  /// No description provided for @timelineOneToTwoYears.
  ///
  /// In en, this message translates to:
  /// **'In 1–2 years'**
  String get timelineOneToTwoYears;

  /// No description provided for @timelineMoreThanTwoYears.
  ///
  /// In en, this message translates to:
  /// **'In more than 2 years'**
  String get timelineMoreThanTwoYears;

  /// No description provided for @relocationYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, I would relocate'**
  String get relocationYes;

  /// No description provided for @relocationOpen.
  ///
  /// In en, this message translates to:
  /// **'Open to discussing it'**
  String get relocationOpen;

  /// No description provided for @relocationNo.
  ///
  /// In en, this message translates to:
  /// **'No, I plan to stay where I am'**
  String get relocationNo;

  /// No description provided for @educationSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary school'**
  String get educationSecondary;

  /// No description provided for @educationDiploma.
  ///
  /// In en, this message translates to:
  /// **'Diploma or vocational training'**
  String get educationDiploma;

  /// No description provided for @educationBachelors.
  ///
  /// In en, this message translates to:
  /// **'Bachelor\'s degree'**
  String get educationBachelors;

  /// No description provided for @educationMasters.
  ///
  /// In en, this message translates to:
  /// **'Master\'s degree'**
  String get educationMasters;

  /// No description provided for @educationDoctorate.
  ///
  /// In en, this message translates to:
  /// **'Doctorate (PhD)'**
  String get educationDoctorate;

  /// No description provided for @educationIslamicStudies.
  ///
  /// In en, this message translates to:
  /// **'Islamic studies qualification'**
  String get educationIslamicStudies;

  /// No description provided for @optionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get optionOther;

  /// No description provided for @professionAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get professionAccountant;

  /// No description provided for @professionArchitect.
  ///
  /// In en, this message translates to:
  /// **'Architect'**
  String get professionArchitect;

  /// No description provided for @professionBankingFinance.
  ///
  /// In en, this message translates to:
  /// **'Banking and finance'**
  String get professionBankingFinance;

  /// No description provided for @professionBusinessOwner.
  ///
  /// In en, this message translates to:
  /// **'Business owner'**
  String get professionBusinessOwner;

  /// No description provided for @professionChef.
  ///
  /// In en, this message translates to:
  /// **'Chef or catering'**
  String get professionChef;

  /// No description provided for @professionCivilServant.
  ///
  /// In en, this message translates to:
  /// **'Civil servant'**
  String get professionCivilServant;

  /// No description provided for @professionConstructionTrades.
  ///
  /// In en, this message translates to:
  /// **'Construction and trades'**
  String get professionConstructionTrades;

  /// No description provided for @professionCustomerService.
  ///
  /// In en, this message translates to:
  /// **'Customer service'**
  String get professionCustomerService;

  /// No description provided for @professionDentist.
  ///
  /// In en, this message translates to:
  /// **'Dentist'**
  String get professionDentist;

  /// No description provided for @professionDesignerCreative.
  ///
  /// In en, this message translates to:
  /// **'Designer or creative'**
  String get professionDesignerCreative;

  /// No description provided for @professionDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get professionDoctor;

  /// No description provided for @professionDriverTransport.
  ///
  /// In en, this message translates to:
  /// **'Driver or transport'**
  String get professionDriverTransport;

  /// No description provided for @professionElectrician.
  ///
  /// In en, this message translates to:
  /// **'Electrician'**
  String get professionElectrician;

  /// No description provided for @professionEngineer.
  ///
  /// In en, this message translates to:
  /// **'Engineer'**
  String get professionEngineer;

  /// No description provided for @professionFarmerAgriculture.
  ///
  /// In en, this message translates to:
  /// **'Farming and agriculture'**
  String get professionFarmerAgriculture;

  /// No description provided for @professionHealthcareAssistant.
  ///
  /// In en, this message translates to:
  /// **'Care or healthcare assistant'**
  String get professionHealthcareAssistant;

  /// No description provided for @professionHomemaker.
  ///
  /// In en, this message translates to:
  /// **'Homemaker'**
  String get professionHomemaker;

  /// No description provided for @professionHospitality.
  ///
  /// In en, this message translates to:
  /// **'Hospitality'**
  String get professionHospitality;

  /// No description provided for @professionHumanResources.
  ///
  /// In en, this message translates to:
  /// **'Human resources'**
  String get professionHumanResources;

  /// No description provided for @professionImamIslamicScholar.
  ///
  /// In en, this message translates to:
  /// **'Imam or Islamic scholar'**
  String get professionImamIslamicScholar;

  /// No description provided for @professionItSoftware.
  ///
  /// In en, this message translates to:
  /// **'IT and software'**
  String get professionItSoftware;

  /// No description provided for @professionJournalistMedia.
  ///
  /// In en, this message translates to:
  /// **'Journalism and media'**
  String get professionJournalistMedia;

  /// No description provided for @professionLawyer.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get professionLawyer;

  /// No description provided for @professionLecturer.
  ///
  /// In en, this message translates to:
  /// **'Lecturer or academic'**
  String get professionLecturer;

  /// No description provided for @professionLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics and supply chain'**
  String get professionLogistics;

  /// No description provided for @professionMarketingSales.
  ///
  /// In en, this message translates to:
  /// **'Marketing and sales'**
  String get professionMarketingSales;

  /// No description provided for @professionMechanic.
  ///
  /// In en, this message translates to:
  /// **'Mechanic'**
  String get professionMechanic;

  /// No description provided for @professionMilitaryDefence.
  ///
  /// In en, this message translates to:
  /// **'Military and defence'**
  String get professionMilitaryDefence;

  /// No description provided for @professionNgoHumanitarian.
  ///
  /// In en, this message translates to:
  /// **'NGO or humanitarian work'**
  String get professionNgoHumanitarian;

  /// No description provided for @professionNurse.
  ///
  /// In en, this message translates to:
  /// **'Nurse'**
  String get professionNurse;

  /// No description provided for @professionPharmacist.
  ///
  /// In en, this message translates to:
  /// **'Pharmacist'**
  String get professionPharmacist;

  /// No description provided for @professionPilotAviation.
  ///
  /// In en, this message translates to:
  /// **'Pilot or aviation'**
  String get professionPilotAviation;

  /// No description provided for @professionPoliceSecurity.
  ///
  /// In en, this message translates to:
  /// **'Police or security'**
  String get professionPoliceSecurity;

  /// No description provided for @professionProjectManager.
  ///
  /// In en, this message translates to:
  /// **'Project manager'**
  String get professionProjectManager;

  /// No description provided for @professionPsychologistCounsellor.
  ///
  /// In en, this message translates to:
  /// **'Psychologist or counsellor'**
  String get professionPsychologistCounsellor;

  /// No description provided for @professionRealEstate.
  ///
  /// In en, this message translates to:
  /// **'Real estate'**
  String get professionRealEstate;

  /// No description provided for @professionResearcherScientist.
  ///
  /// In en, this message translates to:
  /// **'Researcher or scientist'**
  String get professionResearcherScientist;

  /// No description provided for @professionRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get professionRetail;

  /// No description provided for @professionSocialWorker.
  ///
  /// In en, this message translates to:
  /// **'Social worker'**
  String get professionSocialWorker;

  /// No description provided for @professionStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get professionStudent;

  /// No description provided for @professionTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get professionTeacher;

  /// No description provided for @professionTranslatorInterpreter.
  ///
  /// In en, this message translates to:
  /// **'Translator or interpreter'**
  String get professionTranslatorInterpreter;

  /// No description provided for @professionLookingForWork.
  ///
  /// In en, this message translates to:
  /// **'Looking for work'**
  String get professionLookingForWork;

  /// No description provided for @professionRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get professionRetired;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveChanges;

  /// No description provided for @profileCancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancelEdit;

  /// No description provided for @profileLockedNotice.
  ///
  /// In en, this message translates to:
  /// **'Gender and date of birth cannot be changed after your profile is created.'**
  String get profileLockedNotice;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah, your changes are saved.'**
  String get profileUpdated;

  /// No description provided for @emailVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get emailVerifyTitle;

  /// No description provided for @emailVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to {email}. A verified email will be required before you can meet other members.'**
  String emailVerifyBody(String email);

  /// No description provided for @emailVerifyCheck.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified it'**
  String get emailVerifyCheck;

  /// No description provided for @emailVerifyResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get emailVerifyResend;

  /// No description provided for @emailVerifySent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox and spam folder.'**
  String get emailVerifySent;

  /// No description provided for @emailVerifyNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet. Open the link in the email, then try again.'**
  String get emailVerifyNotYet;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerified;

  /// No description provided for @accountActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again.'**
  String get accountActionFailed;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your Shukaansi profile, your private details and your sign-in account. It cannot be undone.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeletePassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get accountDeletePassword;

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'I understand this is permanent'**
  String get accountDeleteConfirm;

  /// No description provided for @accountDeleteConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm that you understand.'**
  String get accountDeleteConfirmRequired;

  /// No description provided for @accountDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my account permanently'**
  String get accountDeleteButton;

  /// No description provided for @accountDeleteWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'That password is not correct.'**
  String get accountDeleteWrongPassword;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Your account could not be deleted. Nothing was removed. Check your connection and try again.'**
  String get accountDeleteFailed;

  /// No description provided for @accountDeletePartial.
  ///
  /// In en, this message translates to:
  /// **'Your profile was deleted, but your sign-in account was not. Try again to finish.'**
  String get accountDeletePartial;

  /// No description provided for @photosTitle.
  ///
  /// In en, this message translates to:
  /// **'Your photos'**
  String get photosTitle;

  /// No description provided for @photosHint.
  ///
  /// In en, this message translates to:
  /// **'Add up to 6 photos. Your first photo is your main photo. Only you can see them for now.'**
  String get photosHint;

  /// No description provided for @photosAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get photosAdd;

  /// No description provided for @photosMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get photosMain;

  /// No description provided for @photosMakeMain.
  ///
  /// In en, this message translates to:
  /// **'Make main photo'**
  String get photosMakeMain;

  /// No description provided for @photosRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photosRemove;

  /// No description provided for @photosView.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get photosView;

  /// No description provided for @photosUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo'**
  String get photosUploading;

  /// No description provided for @photosUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be uploaded. Check your connection and try again.'**
  String get photosUploadFailed;

  /// No description provided for @photosUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPEG, PNG or WebP photo. Very large photos cannot be used.'**
  String get photosUnsupported;

  /// No description provided for @photosUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Your photos could not be updated. Try again.'**
  String get photosUpdateFailed;

  /// No description provided for @photosLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your photos could not be loaded.'**
  String get photosLoadFailed;

  /// No description provided for @photosPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Your photos could not be opened. Check photo permission in your phone settings.'**
  String get photosPickFailed;

  /// No description provided for @photosSlot.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String photosSlot(int number);

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Get verified'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In en, this message translates to:
  /// **'Take a selfie so our team can confirm you match your photos. Verified profiles earn more trust from members and their families.'**
  String get verifyBody;

  /// No description provided for @verifyStart.
  ///
  /// In en, this message translates to:
  /// **'Start verification'**
  String get verifyStart;

  /// No description provided for @verifyNeedsPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo first.'**
  String get verifyNeedsPhoto;

  /// No description provided for @verifyPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification in review'**
  String get verifyPendingTitle;

  /// No description provided for @verifyPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Our team will review your selfie soon, InshaAllah. The result will appear here.'**
  String get verifyPendingBody;

  /// No description provided for @verifyVerified.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah, your profile is verified'**
  String get verifyVerified;

  /// No description provided for @verifyRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification not approved'**
  String get verifyRejectedTitle;

  /// No description provided for @verifyRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Your selfie could not be matched to your photos. Check the tips and try again.'**
  String get verifyRejectedBody;

  /// No description provided for @verifyReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Reviewer note: {note}'**
  String verifyReviewNote(String note);

  /// No description provided for @verifyScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your profile'**
  String get verifyScreenTitle;

  /// No description provided for @verifyTipsIntro.
  ///
  /// In en, this message translates to:
  /// **'For a quick review:'**
  String get verifyTipsIntro;

  /// No description provided for @verifyTipLight.
  ///
  /// In en, this message translates to:
  /// **'Use good light and face the camera.'**
  String get verifyTipLight;

  /// No description provided for @verifyTipFace.
  ///
  /// In en, this message translates to:
  /// **'Keep your face clearly visible, without sunglasses or filters.'**
  String get verifyTipFace;

  /// No description provided for @verifyTipPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your selfie is private. Only our review team sees it, and it is never shown on your profile.'**
  String get verifyTipPrivate;

  /// No description provided for @verifyTakeSelfie.
  ///
  /// In en, this message translates to:
  /// **'Take selfie'**
  String get verifyTakeSelfie;

  /// No description provided for @verifyRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get verifyRetake;

  /// No description provided for @verifySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get verifySubmit;

  /// No description provided for @verifySubmitting.
  ///
  /// In en, this message translates to:
  /// **'Sending your selfie'**
  String get verifySubmitting;

  /// No description provided for @verifySubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Your selfie could not be sent. Check your connection and try again.'**
  String get verifySubmitFailed;

  /// No description provided for @verifyCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be opened. Check camera permission in your phone settings.'**
  String get verifyCameraFailed;

  /// No description provided for @verifySelfiePreview.
  ///
  /// In en, this message translates to:
  /// **'Your selfie'**
  String get verifySelfiePreview;

  /// No description provided for @photosResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset verification?'**
  String get photosResetTitle;

  /// No description provided for @photosResetBody.
  ///
  /// In en, this message translates to:
  /// **'Your verification is linked to your main photo. Changing your main photo resets it, and you will need to take a new selfie to be verified again.'**
  String get photosResetBody;

  /// No description provided for @photosResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get photosResetConfirm;

  /// No description provided for @verifyTipNiqab.
  ///
  /// In en, this message translates to:
  /// **'If you wear a niqab, please remove it for this selfie only. Your face must be visible for verification. The selfie stays private and is seen only by our review team.'**
  String get verifyTipNiqab;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get navProfile;

  /// No description provided for @discoverNotListedTitle.
  ///
  /// In en, this message translates to:
  /// **'Get ready to be discovered'**
  String get discoverNotListedTitle;

  /// No description provided for @discoverNotListedBody.
  ///
  /// In en, this message translates to:
  /// **'Complete these steps to appear in Discover and to see other members.'**
  String get discoverNotListedBody;

  /// No description provided for @discoverNeedEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email address'**
  String get discoverNeedEmail;

  /// No description provided for @discoverNeedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one profile photo'**
  String get discoverNeedPhoto;

  /// No description provided for @discoverGoToProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to my profile'**
  String get discoverGoToProfile;

  /// No description provided for @discoverCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get discoverCheckAgain;

  /// No description provided for @discoverEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profiles match yet. Try widening your filters or check back soon, InshaAllah.'**
  String get discoverEmpty;

  /// No description provided for @discoverLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Profiles could not be loaded. Check your connection and try again.'**
  String get discoverLoadFailed;

  /// No description provided for @discoverFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get discoverFilters;

  /// No description provided for @discoverAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Age {min} to {max}'**
  String discoverAgeRange(int min, int max);

  /// No description provided for @discoverAnyCountry.
  ///
  /// In en, this message translates to:
  /// **'Any country'**
  String get discoverAnyCountry;

  /// No description provided for @discoverCountry.
  ///
  /// In en, this message translates to:
  /// **'Country they live in'**
  String get discoverCountry;

  /// No description provided for @discoverApply.
  ///
  /// In en, this message translates to:
  /// **'Show profiles'**
  String get discoverApply;

  /// No description provided for @discoverReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get discoverReset;

  /// No description provided for @cardNameAge.
  ///
  /// In en, this message translates to:
  /// **'{name}, {age}'**
  String cardNameAge(String name, int age);

  /// No description provided for @cardLocation.
  ///
  /// In en, this message translates to:
  /// **'{city}, {country}'**
  String cardLocation(String city, String country);

  /// No description provided for @verifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified profile'**
  String get verifiedBadge;

  /// No description provided for @photoOf.
  ///
  /// In en, this message translates to:
  /// **'Photo {current} of {total}'**
  String photoOf(int current, int total);

  /// No description provided for @photosPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos are private'**
  String get photosPrivateTitle;

  /// No description provided for @photosPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'She shares her photos with members she approves.'**
  String get photosPrivateBody;

  /// No description provided for @photosRequest.
  ///
  /// In en, this message translates to:
  /// **'Request photos'**
  String get photosRequest;

  /// No description provided for @photosRequested.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get photosRequested;

  /// No description provided for @photosCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get photosCancelRequest;

  /// No description provided for @photosRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Your request could not be sent. Try again.'**
  String get photosRequestFailed;

  /// No description provided for @blurTitle.
  ///
  /// In en, this message translates to:
  /// **'Blur my photos in Discover'**
  String get blurTitle;

  /// No description provided for @blurBody.
  ///
  /// In en, this message translates to:
  /// **'Members see a blurred version until you approve their request.'**
  String get blurBody;

  /// No description provided for @blurFailed.
  ///
  /// In en, this message translates to:
  /// **'Your photo privacy could not be changed. Try again.'**
  String get blurFailed;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo requests'**
  String get requestsTitle;

  /// No description provided for @requestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No requests right now.'**
  String get requestsEmpty;

  /// No description provided for @requestsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get requestsApprove;

  /// No description provided for @requestsDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get requestsDecline;

  /// No description provided for @viewersTitle.
  ///
  /// In en, this message translates to:
  /// **'Can see your photos'**
  String get viewersTitle;

  /// No description provided for @viewersRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get viewersRemove;

  /// No description provided for @requestsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Requests could not be loaded.'**
  String get requestsLoadFailed;

  /// No description provided for @filterPractice.
  ///
  /// In en, this message translates to:
  /// **'Religious practice'**
  String get filterPractice;

  /// No description provided for @reportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportAction;

  /// No description provided for @blockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockAction;

  /// No description provided for @cardMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More options for {name}'**
  String cardMoreActions(String name);

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String reportTitle(String name);

  /// No description provided for @reportBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what is wrong. Reports are confidential: {name} will not know who reported them.'**
  String reportBody(String name);

  /// No description provided for @reportReasonFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile or impersonation'**
  String get reportReasonFakeProfile;

  /// No description provided for @reportReasonInappropriatePhotos.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate photos'**
  String get reportReasonInappropriatePhotos;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or disrespect'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonScam.
  ///
  /// In en, this message translates to:
  /// **'Scam or asking for money'**
  String get reportReasonScam;

  /// No description provided for @reportReasonUnderage.
  ///
  /// In en, this message translates to:
  /// **'May be under 18'**
  String get reportReasonUnderage;

  /// No description provided for @reportReasonNotSerious.
  ///
  /// In en, this message translates to:
  /// **'Not serious about marriage'**
  String get reportReasonNotSerious;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// No description provided for @reportNote.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportNote;

  /// No description provided for @reportAlsoBlock.
  ///
  /// In en, this message translates to:
  /// **'Also block {name}'**
  String reportAlsoBlock(String name);

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSubmit;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'JazakAllahu khayran. Our team will review your report.'**
  String get reportSent;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Your report could not be sent. Try again.'**
  String get reportFailed;

  /// No description provided for @blockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockTitle(String name);

  /// No description provided for @blockBody.
  ///
  /// In en, this message translates to:
  /// **'You will no longer see each other in Discover, and photo permissions between you end. They are not told.'**
  String get blockBody;

  /// No description provided for @blockFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not block. Try again.'**
  String get blockFailed;

  /// No description provided for @blockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked members'**
  String get blockedTitle;

  /// No description provided for @unblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockAction;

  /// No description provided for @suspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended'**
  String get suspendedTitle;

  /// No description provided for @suspendedBody.
  ///
  /// In en, this message translates to:
  /// **'You cannot use Shukaansi while your account is suspended.'**
  String get suspendedBody;

  /// No description provided for @suspendedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String suspendedReason(String reason);

  /// No description provided for @suspendedContact.
  ///
  /// In en, this message translates to:
  /// **'To appeal, contact {email}.'**
  String suspendedContact(String email);

  /// No description provided for @stepsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} complete'**
  String stepsDone(int done, int total);

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} added'**
  String photosCount(int count, int max);

  /// No description provided for @verifyStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get verifyStatusNotStarted;

  /// No description provided for @verifyStatusPending.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get verifyStatusPending;

  /// No description provided for @verifyStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get verifyStatusRejected;

  /// No description provided for @navLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get navLikes;

  /// No description provided for @navMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navMatches;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @matchesSoonBody.
  ///
  /// In en, this message translates to:
  /// **'When two members show interest in each other, it becomes a match. Your matches will appear here.'**
  String get matchesSoonBody;

  /// No description provided for @browseDiscover.
  ///
  /// In en, this message translates to:
  /// **'Browse Discover'**
  String get browseDiscover;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you continue'**
  String get legalTitle;

  /// No description provided for @legalBody.
  ///
  /// In en, this message translates to:
  /// **'Please read our Terms of Use and Privacy Policy. They follow Islamic manners and explain how we protect your information.'**
  String get legalBody;

  /// No description provided for @legalTermsPoint.
  ///
  /// In en, this message translates to:
  /// **'Seeking marriage with honesty, modesty and respect.'**
  String get legalTermsPoint;

  /// No description provided for @legalPrivacyPoint.
  ///
  /// In en, this message translates to:
  /// **'Your data is never sold or shared with advertisers.'**
  String get legalPrivacyPoint;

  /// No description provided for @legalAgree.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Terms of Use and Privacy Policy.'**
  String get legalAgree;

  /// No description provided for @legalContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get legalContinue;

  /// No description provided for @legalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your agreement. Check your connection and try again.'**
  String get legalSaveFailed;

  /// No description provided for @legalCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t check your account. Check your connection and try again.'**
  String get legalCheckFailed;

  /// No description provided for @legalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This document couldn\'t be opened.'**
  String get legalLoadFailed;

  /// No description provided for @verifyStepPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get verifyStepPhoto;

  /// No description provided for @verifyStepSelfie.
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get verifyStepSelfie;

  /// No description provided for @verifyStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get verifyStepReview;

  /// No description provided for @stepStateDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get stepStateDone;

  /// No description provided for @stepStateCurrent.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get stepStateCurrent;

  /// No description provided for @stepStateUpcoming.
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get stepStateUpcoming;

  /// No description provided for @verifyHeadline.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you'**
  String get verifyHeadline;

  /// No description provided for @verifyIntro.
  ///
  /// In en, this message translates to:
  /// **'Take a quick selfie so our team can compare it with your main photo.'**
  String get verifyIntro;

  /// No description provided for @verifyPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private and secure'**
  String get verifyPrivateTitle;

  /// No description provided for @verifyCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviewed with care'**
  String get verifyCareTitle;

  /// No description provided for @verifyCareBody.
  ///
  /// In en, this message translates to:
  /// **'We use it only to confirm that it\'s really you.'**
  String get verifyCareBody;

  /// No description provided for @verifyCheckHeadline.
  ///
  /// In en, this message translates to:
  /// **'Check your selfie'**
  String get verifyCheckHeadline;

  /// No description provided for @verifyCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Make sure your face is clear and well lit, then send it for review.'**
  String get verifyCheckBody;

  /// No description provided for @verifySubmittedChip.
  ///
  /// In en, this message translates to:
  /// **'Selfie submitted'**
  String get verifySubmittedChip;

  /// No description provided for @verifySubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your verification is in review'**
  String get verifySubmittedTitle;

  /// No description provided for @verifySubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'JazakAllahu khayran. Our team will compare your selfie with your main photo and let you know here, InshaAllah.'**
  String get verifySubmittedBody;

  /// No description provided for @reviewStepProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile completed'**
  String get reviewStepProfile;

  /// No description provided for @reviewStepProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Your details and photos are saved.'**
  String get reviewStepProfileBody;

  /// No description provided for @reviewStepReview.
  ///
  /// In en, this message translates to:
  /// **'Verification review'**
  String get reviewStepReview;

  /// No description provided for @reviewStepReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Our team checks every selfie by hand.'**
  String get reviewStepReviewBody;

  /// No description provided for @reviewStepBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified badge'**
  String get reviewStepBadge;

  /// No description provided for @reviewStepBadgeBody.
  ///
  /// In en, this message translates to:
  /// **'Once approved, your profile shows the blue verified badge, InshaAllah.'**
  String get reviewStepBadgeBody;

  /// No description provided for @verifyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to Shukaansi'**
  String get verifyContinue;

  /// No description provided for @likeAction.
  ///
  /// In en, this message translates to:
  /// **'Show interest'**
  String get likeAction;

  /// No description provided for @withdrawInterest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw interest'**
  String get withdrawInterest;

  /// No description provided for @matchedLabel.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get matchedLabel;

  /// No description provided for @likeSent.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah, your interest was sent to {name}.'**
  String likeSent(String name);

  /// No description provided for @interestFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Check your connection and try again.'**
  String get interestFailed;

  /// No description provided for @matchTitle.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah, it\'s a match!'**
  String get matchTitle;

  /// No description provided for @matchBody.
  ///
  /// In en, this message translates to:
  /// **'You and {name} have both shown interest. May Allah put khayr in it.'**
  String matchBody(String name);

  /// No description provided for @matchPhotosNote.
  ///
  /// In en, this message translates to:
  /// **'You can now see each other\'s photos.'**
  String get matchPhotosNote;

  /// No description provided for @matchMessagingSoon.
  ///
  /// In en, this message translates to:
  /// **'Messaging opens soon, InshaAllah.'**
  String get matchMessagingSoon;

  /// No description provided for @viewMatches.
  ///
  /// In en, this message translates to:
  /// **'View matches'**
  String get viewMatches;

  /// No description provided for @keepBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Keep browsing'**
  String get keepBrowsing;

  /// No description provided for @likesReceivedTab.
  ///
  /// In en, this message translates to:
  /// **'Liked you'**
  String get likesReceivedTab;

  /// No description provided for @likesSentTab.
  ///
  /// In en, this message translates to:
  /// **'You liked'**
  String get likesSentTab;

  /// No description provided for @likesReceivedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one has shown interest yet. Keep your profile complete and check back soon, InshaAllah.'**
  String get likesReceivedEmpty;

  /// No description provided for @likesSentEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t shown interest in anyone yet. Tap the heart on a profile in Discover.'**
  String get likesSentEmpty;

  /// No description provided for @likeBack.
  ///
  /// In en, this message translates to:
  /// **'Like back'**
  String get likeBack;

  /// No description provided for @declineInterest.
  ///
  /// In en, this message translates to:
  /// **'Not for me'**
  String get declineInterest;

  /// No description provided for @likesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Likes could not be loaded.'**
  String get likesLoadFailed;

  /// No description provided for @matchesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get matchesEmptyTitle;

  /// No description provided for @matchesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Matches could not be loaded.'**
  String get matchesLoadFailed;

  /// No description provided for @unmatch.
  ///
  /// In en, this message translates to:
  /// **'Unmatch'**
  String get unmatch;

  /// No description provided for @unmatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Unmatch {name}?'**
  String unmatchTitle(String name);

  /// No description provided for @unmatchBody.
  ///
  /// In en, this message translates to:
  /// **'You will no longer be matched and photo sharing between you ends. You would both need to show interest again to match.'**
  String get unmatchBody;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @likesNewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String likesNewCount(int count);

  /// No description provided for @discoverForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get discoverForYou;

  /// No description provided for @discoverNewMembers.
  ///
  /// In en, this message translates to:
  /// **'New members'**
  String get discoverNewMembers;

  /// No description provided for @forYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Members who suit your partner preferences.'**
  String get forYouSubtitle;

  /// No description provided for @newMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The newest members, most recent first.'**
  String get newMembersSubtitle;

  /// No description provided for @forYouSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us who you\'re looking for'**
  String get forYouSetupTitle;

  /// No description provided for @forYouSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Set your partner preferences and we\'ll show you members who suit them, InshaAllah.'**
  String get forYouSetupBody;

  /// No description provided for @setPreferences.
  ///
  /// In en, this message translates to:
  /// **'Set preferences'**
  String get setPreferences;

  /// No description provided for @partnerPreferences.
  ///
  /// In en, this message translates to:
  /// **'Partner preferences'**
  String get partnerPreferences;

  /// No description provided for @prefCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries they live in'**
  String get prefCountries;

  /// No description provided for @prefCountriesHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for any country. Choose up to 10.'**
  String get prefCountriesHint;

  /// No description provided for @prefAddCountry.
  ///
  /// In en, this message translates to:
  /// **'Add country'**
  String get prefAddCountry;

  /// No description provided for @prefRemoveCountry.
  ///
  /// In en, this message translates to:
  /// **'Remove {country}'**
  String prefRemoveCountry(String country);

  /// No description provided for @prefSave.
  ///
  /// In en, this message translates to:
  /// **'Save preferences'**
  String get prefSave;

  /// No description provided for @prefSaved.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah, your preferences are saved.'**
  String get prefSaved;

  /// No description provided for @prefSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your preferences could not be saved. Try again.'**
  String get prefSaveFailed;

  /// No description provided for @prefNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get prefNotSet;

  /// No description provided for @prefAges.
  ///
  /// In en, this message translates to:
  /// **'Ages {min}–{max}'**
  String prefAges(int min, int max);

  /// No description provided for @prefCountryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 country} other{{count} countries}}'**
  String prefCountryCount(int count);

  /// No description provided for @prefAnyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get prefAnyAnswer;

  /// No description provided for @roleTitle.
  ///
  /// In en, this message translates to:
  /// **'How will you use Shukaansi?'**
  String get roleTitle;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking for a spouse'**
  String get roleMember;

  /// No description provided for @roleMemberBody.
  ///
  /// In en, this message translates to:
  /// **'Create your profile and meet Muslims seeking marriage.'**
  String get roleMemberBody;

  /// No description provided for @roleWali.
  ///
  /// In en, this message translates to:
  /// **'I\'m a Wali'**
  String get roleWali;

  /// No description provided for @roleWaliBody.
  ///
  /// In en, this message translates to:
  /// **'A family member invited you to approve their matches.'**
  String get roleWaliBody;

  /// No description provided for @waliSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Join as a Wali'**
  String get waliSetupTitle;

  /// No description provided for @waliSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your name and the code your family member shared with you.'**
  String get waliSetupBody;

  /// No description provided for @waliYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get waliYourName;

  /// No description provided for @waliCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get waliCode;

  /// No description provided for @waliJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get waliJoin;

  /// No description provided for @waliCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'This code isn\'t valid or has expired. Ask for a new one.'**
  String get waliCodeInvalid;

  /// No description provided for @waliHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Wali'**
  String get waliHomeTitle;

  /// No description provided for @waliGreeting.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum, {name}'**
  String waliGreeting(String name);

  /// No description provided for @waliGuarding.
  ///
  /// In en, this message translates to:
  /// **'You are the Wali for {names}.'**
  String waliGuarding(String names);

  /// No description provided for @waliNoMembers.
  ///
  /// In en, this message translates to:
  /// **'You aren\'t the Wali for anyone yet. Ask your family member for an invite code.'**
  String get waliNoMembers;

  /// No description provided for @waliAddMember.
  ///
  /// In en, this message translates to:
  /// **'Enter another code'**
  String get waliAddMember;

  /// No description provided for @waliRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Match requests'**
  String get waliRequestsTitle;

  /// No description provided for @waliNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No match requests yet. You\'ll be asked here when there is a new match, InshaAllah.'**
  String get waliNoRequests;

  /// No description provided for @waliRequestFor.
  ///
  /// In en, this message translates to:
  /// **'Match for {name}'**
  String waliRequestFor(String name);

  /// No description provided for @waliApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get waliApprove;

  /// No description provided for @waliDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get waliDecline;

  /// No description provided for @waliApproved.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah, you approved this match. May Allah make it a blessing.'**
  String get waliApproved;

  /// No description provided for @waliDeclined.
  ///
  /// In en, this message translates to:
  /// **'You declined this match.'**
  String get waliDeclined;

  /// No description provided for @waliDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this match?'**
  String get waliDeclineTitle;

  /// No description provided for @waliDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'Both members will see that the match was declined, and they will not be able to message each other.'**
  String get waliDeclineBody;

  /// No description provided for @waliStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get waliStatusApproved;

  /// No description provided for @waliStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get waliStatusDeclined;

  /// No description provided for @waliStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get waliStatusWaiting;

  /// No description provided for @waliStop.
  ///
  /// In en, this message translates to:
  /// **'Stop being Wali for {name}'**
  String waliStop(String name);

  /// No description provided for @waliStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop being Wali for {name}?'**
  String waliStopTitle(String name);

  /// No description provided for @waliStopBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will need to invite a new Wali.'**
  String waliStopBody(String name);

  /// No description provided for @waliPhotosNote.
  ///
  /// In en, this message translates to:
  /// **'Photos are shared only between the two members.'**
  String get waliPhotosNote;

  /// No description provided for @waliLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This couldn\'t be loaded.'**
  String get waliLoadFailed;

  /// No description provided for @waliCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Wali'**
  String get waliCardTitle;

  /// No description provided for @waliRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Required for sisters: your matches can message only after your Wali approves.'**
  String get waliRequiredBody;

  /// No description provided for @waliOptionalBody.
  ///
  /// In en, this message translates to:
  /// **'Optional: add a Wali to approve your matches before messaging.'**
  String get waliOptionalBody;

  /// No description provided for @waliRequiredChip.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get waliRequiredChip;

  /// No description provided for @waliInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite your Wali'**
  String get waliInvite;

  /// No description provided for @waliInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get waliInviteCode;

  /// No description provided for @waliInviteExpires.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String waliInviteExpires(String date);

  /// No description provided for @waliShareCode.
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get waliShareCode;

  /// No description provided for @waliCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get waliCopyCode;

  /// No description provided for @waliCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get waliCopied;

  /// No description provided for @waliNewCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get waliNewCode;

  /// No description provided for @waliShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum. Please be my Wali on Shukaansi. Install the app, choose \"I\'m a Wali\" and enter this code: {code}. It is valid for 7 days.'**
  String waliShareMessage(String code);

  /// No description provided for @waliLinked.
  ///
  /// In en, this message translates to:
  /// **'{name} is your Wali'**
  String waliLinked(String name);

  /// No description provided for @waliLinkedBody.
  ///
  /// In en, this message translates to:
  /// **'Your Wali approves your matches before you can message.'**
  String get waliLinkedBody;

  /// No description provided for @waliRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove Wali'**
  String get waliRemove;

  /// No description provided for @waliRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} as your Wali?'**
  String waliRemoveTitle(String name);

  /// No description provided for @waliRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Their approvals are cleared, and a new Wali will need to approve your matches again.'**
  String get waliRemoveBody;

  /// No description provided for @approvalNeedsWali.
  ///
  /// In en, this message translates to:
  /// **'Add your Wali to continue'**
  String get approvalNeedsWali;

  /// No description provided for @approvalWaitingYours.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your Wali\'s approval'**
  String get approvalWaitingYours;

  /// No description provided for @approvalWaitingTheirs.
  ///
  /// In en, this message translates to:
  /// **'Waiting for their Wali\'s approval'**
  String get approvalWaitingTheirs;

  /// No description provided for @approvalDeclined.
  ///
  /// In en, this message translates to:
  /// **'A Wali declined this match'**
  String get approvalDeclined;

  /// No description provided for @chatsActive.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get chatsActive;

  /// No description provided for @chatsNewMatches.
  ///
  /// In en, this message translates to:
  /// **'New matches'**
  String get chatsNewMatches;

  /// No description provided for @chatsNewMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Say salaam and start a respectful conversation.'**
  String get chatsNewMatchesBody;

  /// No description provided for @chatsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatsEmptyTitle;

  /// No description provided for @chatsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When you both show interest, your match will appear here, InshaAllah.'**
  String get chatsEmptyBody;

  /// No description provided for @viewMatchesAction.
  ///
  /// In en, this message translates to:
  /// **'View matches'**
  String get viewMatchesAction;

  /// No description provided for @chatsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Conversations could not be loaded.'**
  String get chatsLoadFailed;

  /// No description provided for @messageAction.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageAction;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get messageHint;

  /// No description provided for @messageSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get messageSend;

  /// No description provided for @messageSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Your message could not be sent. Try again.'**
  String get messageSendFailed;

  /// No description provided for @chatStarterTitle.
  ///
  /// In en, this message translates to:
  /// **'Begin with salaam'**
  String get chatStarterTitle;

  /// No description provided for @chatStarterBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the conversation respectful and focused on marriage. Involve your families when the time is right.'**
  String get chatStarterBody;

  /// No description provided for @chatStarterSalaam.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum'**
  String get chatStarterSalaam;

  /// No description provided for @chatLocked.
  ///
  /// In en, this message translates to:
  /// **'Messaging opens once the required Wali approval is given.'**
  String get chatLocked;

  /// No description provided for @chatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatYesterday;

  /// No description provided for @chatUnread.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get chatUnread;

  /// No description provided for @chatYou.
  ///
  /// In en, this message translates to:
  /// **'You: {text}'**
  String chatYou(String text);

  /// No description provided for @chatsUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String chatsUnreadCount(int count);

  /// No description provided for @messageFromYou.
  ///
  /// In en, this message translates to:
  /// **'You said'**
  String get messageFromYou;

  /// No description provided for @messageFrom.
  ///
  /// In en, this message translates to:
  /// **'{name} said'**
  String messageFrom(String name);

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get activityTitle;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up. New interest, matches and messages will appear here, InshaAllah.'**
  String get activityEmpty;

  /// No description provided for @activityOpenOnly.
  ///
  /// In en, this message translates to:
  /// **'Alerts appear while Shukaansi is open. Phone notifications when the app is closed are coming soon.'**
  String get activityOpenOnly;

  /// No description provided for @activityLiked.
  ///
  /// In en, this message translates to:
  /// **'{name} showed interest in you'**
  String activityLiked(String name);

  /// No description provided for @activityMatched.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah, you matched with {name}'**
  String activityMatched(String name);

  /// No description provided for @activityYourWaliApproved.
  ///
  /// In en, this message translates to:
  /// **'Your Wali approved your match with {name}'**
  String activityYourWaliApproved(String name);

  /// No description provided for @activityYourWaliDeclined.
  ///
  /// In en, this message translates to:
  /// **'Your Wali declined your match with {name}'**
  String activityYourWaliDeclined(String name);

  /// No description provided for @activityTheirWaliApproved.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Wali approved your match. You can now message, InshaAllah.'**
  String activityTheirWaliApproved(String name);

  /// No description provided for @activityTheirWaliDeclined.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Wali declined the match'**
  String activityTheirWaliDeclined(String name);

  /// No description provided for @activityMessage.
  ///
  /// In en, this message translates to:
  /// **'New message from {name}'**
  String activityMessage(String name);

  /// No description provided for @activityView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get activityView;

  /// No description provided for @activityNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get activityNew;

  /// No description provided for @mutualTitle.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah, you both like each other'**
  String get mutualTitle;

  /// No description provided for @mutualBody.
  ///
  /// In en, this message translates to:
  /// **'A match needs Premium on either side. When either of you upgrades, the match is made, InshaAllah.'**
  String get mutualBody;

  /// No description provided for @mutualNeedsPremium.
  ///
  /// In en, this message translates to:
  /// **'You both like each other: Premium needed to match'**
  String get mutualNeedsPremium;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get viewPlans;

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get plansTitle;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get planPremium;

  /// No description provided for @planVip.
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get planVip;

  /// No description provided for @planHeadlineFree.
  ///
  /// In en, this message translates to:
  /// **'Begin your search'**
  String get planHeadlineFree;

  /// No description provided for @planHeadlinePremium.
  ///
  /// In en, this message translates to:
  /// **'Meet with more choice'**
  String get planHeadlinePremium;

  /// No description provided for @planHeadlineVip.
  ///
  /// In en, this message translates to:
  /// **'Be seen first'**
  String get planHeadlineVip;

  /// No description provided for @planSubFree.
  ///
  /// In en, this message translates to:
  /// **'Everything you need to start, at no cost.'**
  String get planSubFree;

  /// No description provided for @planSubPremium.
  ///
  /// In en, this message translates to:
  /// **'Match with anyone you both like, and message your matches.'**
  String get planSubPremium;

  /// No description provided for @planSubVip.
  ///
  /// In en, this message translates to:
  /// **'Everything in Premium, with priority placement in Discover.'**
  String get planSubVip;

  /// No description provided for @featureProfile.
  ///
  /// In en, this message translates to:
  /// **'Create your profile and get verified'**
  String get featureProfile;

  /// No description provided for @featureBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse Discover and show interest'**
  String get featureBrowse;

  /// No description provided for @featureMatchPremium.
  ///
  /// In en, this message translates to:
  /// **'Match with members who have Premium'**
  String get featureMatchPremium;

  /// No description provided for @featureMatchAnyone.
  ///
  /// In en, this message translates to:
  /// **'Match with anyone you both like'**
  String get featureMatchAnyone;

  /// No description provided for @featureMessage.
  ///
  /// In en, this message translates to:
  /// **'Message your matches, with Wali approval'**
  String get featureMessage;

  /// No description provided for @featurePriority.
  ///
  /// In en, this message translates to:
  /// **'Shown first in Discover'**
  String get featurePriority;

  /// No description provided for @featureEverythingPremium.
  ///
  /// In en, this message translates to:
  /// **'Everything in Premium'**
  String get featureEverythingPremium;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonth;

  /// No description provided for @planCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime.'**
  String get planCancelAnytime;

  /// No description provided for @planContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue with {plan}'**
  String planContinue(String plan);

  /// No description provided for @planCurrent.
  ///
  /// In en, this message translates to:
  /// **'Your current plan'**
  String get planCurrent;

  /// No description provided for @planComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon, InshaAllah'**
  String get planComingSoonTitle;

  /// No description provided for @planComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions through Google Play are on the way. Until then, our team can add Premium or VIP to your account.'**
  String get planComingSoonBody;

  /// No description provided for @planRenewNote.
  ///
  /// In en, this message translates to:
  /// **'When available, subscriptions renew automatically unless cancelled.'**
  String get planRenewNote;

  /// No description provided for @compareAllPlans.
  ///
  /// In en, this message translates to:
  /// **'Compare all plans'**
  String get compareAllPlans;

  /// No description provided for @membershipTitle.
  ///
  /// In en, this message translates to:
  /// **'My membership'**
  String get membershipTitle;

  /// No description provided for @membershipFreeBody.
  ///
  /// In en, this message translates to:
  /// **'Explore Shukaansi with essential features.'**
  String get membershipFreeBody;

  /// No description provided for @membershipActive.
  ///
  /// In en, this message translates to:
  /// **'{plan} until {date}'**
  String membershipActive(String plan, String date);

  /// No description provided for @previewBadge.
  ///
  /// In en, this message translates to:
  /// **'Preview · fictional profiles'**
  String get previewBadge;

  /// No description provided for @previewScenarios.
  ///
  /// In en, this message translates to:
  /// **'Preview scenarios'**
  String get previewScenarios;

  /// No description provided for @previewScenariosBody.
  ///
  /// In en, this message translates to:
  /// **'Everything here is simulated on this device. Nothing is sent to Shukaansi.'**
  String get previewScenariosBody;

  /// No description provided for @scenarioPopulated.
  ///
  /// In en, this message translates to:
  /// **'Members to discover'**
  String get scenarioPopulated;

  /// No description provided for @scenarioPrefsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Preferences not set'**
  String get scenarioPrefsNotSet;

  /// No description provided for @scenarioNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching profiles'**
  String get scenarioNoMatches;

  /// No description provided for @scenarioLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get scenarioLoading;

  /// No description provided for @scenarioNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network failure'**
  String get scenarioNetworkError;

  /// No description provided for @scenarioIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete profile'**
  String get scenarioIncomplete;

  /// No description provided for @scenarioAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Verification in review'**
  String get scenarioAwaitingReview;

  /// No description provided for @scenarioEmptyActivity.
  ///
  /// In en, this message translates to:
  /// **'No likes or conversations'**
  String get scenarioEmptyActivity;

  /// No description provided for @previewSimulatePremium.
  ///
  /// In en, this message translates to:
  /// **'Simulate Premium for this account'**
  String get previewSimulatePremium;

  /// No description provided for @previewNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This action isn\'t available in the preview.'**
  String get previewNotAvailable;

  /// No description provided for @previewDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview is turned off'**
  String get previewDisabledTitle;

  /// No description provided for @previewDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Run a debug or profile build with --dart-define=SHUKAANSI_PREVIEW=true.'**
  String get previewDisabledBody;

  /// No description provided for @photoVerified.
  ///
  /// In en, this message translates to:
  /// **'Photo verified'**
  String get photoVerified;

  /// No description provided for @photoVerifiedInfo.
  ///
  /// In en, this message translates to:
  /// **'Our team compared a private selfie with this member\'s photos. It does not confirm identity documents.'**
  String get photoVerifiedInfo;

  /// No description provided for @aboutName.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String aboutName(String name);

  /// No description provided for @marriagePlans.
  ///
  /// In en, this message translates to:
  /// **'Marriage plans: {timeline}'**
  String marriagePlans(String timeline);

  /// No description provided for @sectionBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get sectionBackground;

  /// No description provided for @factLivesIn.
  ///
  /// In en, this message translates to:
  /// **'Lives in'**
  String get factLivesIn;

  /// No description provided for @factPractice.
  ///
  /// In en, this message translates to:
  /// **'Religious practice'**
  String get factPractice;

  /// No description provided for @factRelocation.
  ///
  /// In en, this message translates to:
  /// **'Open to relocating'**
  String get factRelocation;

  /// No description provided for @conceptLabel.
  ///
  /// In en, this message translates to:
  /// **'Concept'**
  String get conceptLabel;

  /// No description provided for @interestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interestsTitle;

  /// No description provided for @photoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This photo couldn\'t load.'**
  String get photoLoadFailed;

  /// No description provided for @closePhoto.
  ///
  /// In en, this message translates to:
  /// **'Close photo'**
  String get closePhoto;

  /// No description provided for @openPhoto.
  ///
  /// In en, this message translates to:
  /// **'Open photo {current} of {total}'**
  String openPhoto(int current, int total);

  /// No description provided for @passAction.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get passAction;

  /// No description provided for @passedName.
  ///
  /// In en, this message translates to:
  /// **'You passed on {name}'**
  String passedName(String name);

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// No description provided for @seenEveryoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen everyone for now'**
  String get seenEveryoneTitle;

  /// No description provided for @seenEveryoneBody.
  ///
  /// In en, this message translates to:
  /// **'New members join regularly. Check again later, InshaAllah.'**
  String get seenEveryoneBody;

  /// No description provided for @noMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No members match your preferences'**
  String get noMatchesTitle;

  /// No description provided for @noMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Try a wider age range or more countries.'**
  String get noMatchesBody;

  /// No description provided for @adjustPreferences.
  ///
  /// In en, this message translates to:
  /// **'Adjust preferences'**
  String get adjustPreferences;

  /// No description provided for @networkErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect'**
  String get networkErrorTitle;

  /// No description provided for @networkErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get networkErrorBody;

  /// No description provided for @newMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No new members yet. Check again soon, InshaAllah.'**
  String get newMembersEmpty;

  /// No description provided for @likeStatusLikesYou.
  ///
  /// In en, this message translates to:
  /// **'Likes you'**
  String get likeStatusLikesYou;

  /// No description provided for @likeStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a reply'**
  String get likeStatusWaiting;

  /// No description provided for @likeStatusMutual.
  ///
  /// In en, this message translates to:
  /// **'You both like each other'**
  String get likeStatusMutual;

  /// No description provided for @profileProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get profileProgressTitle;

  /// No description provided for @progressAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get progressAccount;

  /// No description provided for @progressAccountTodo.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get progressAccountTodo;

  /// No description provided for @progressProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get progressProfile;

  /// No description provided for @progressVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible in Discover'**
  String get progressVisible;

  /// No description provided for @progressAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo to appear in Discover'**
  String get progressAddPhoto;

  /// No description provided for @progressVerification.
  ///
  /// In en, this message translates to:
  /// **'Photo verification'**
  String get progressVerification;

  /// No description provided for @verifyStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifyStatusVerified;

  /// No description provided for @previewProfile.
  ///
  /// In en, this message translates to:
  /// **'Preview profile'**
  String get previewProfile;

  /// No description provided for @managePhotos.
  ///
  /// In en, this message translates to:
  /// **'Manage photos'**
  String get managePhotos;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @yourPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans and preferences'**
  String get yourPlans;

  /// No description provided for @profilePrivateDetails.
  ///
  /// In en, this message translates to:
  /// **'All your answers, including private details'**
  String get profilePrivateDetails;

  /// No description provided for @chatsStartHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a new match to see their profile and say salaam.'**
  String get chatsStartHint;

  /// No description provided for @loadingSlow.
  ///
  /// In en, this message translates to:
  /// **'Taking longer than usual?'**
  String get loadingSlow;

  /// No description provided for @profileComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String profileComplete(int percent);

  /// No description provided for @verifyNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your photo to get more trust'**
  String get verifyNudgeTitle;

  /// No description provided for @verifyNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'Members and families trust verified profiles more. It only takes a quick selfie.'**
  String get verifyNudgeBody;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint, face or PIN'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Asks when Shukaansi opens, or after 5 minutes away'**
  String get appLockSubtitle;

  /// No description provided for @appLockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Shukaansi'**
  String get appLockReason;

  /// No description provided for @appLockEnableReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to turn on app lock'**
  String get appLockEnableReason;

  /// No description provided for @appLockOn.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah, app lock is on'**
  String get appLockOn;

  /// No description provided for @appLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Set up a fingerprint, face or screen lock on your phone first.'**
  String get appLockUnavailable;

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Shukaansi is locked'**
  String get lockedTitle;

  /// No description provided for @lockedBody.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint, face or phone PIN to continue.'**
  String get lockedBody;

  /// No description provided for @unlockAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockAction;

  /// No description provided for @unlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock. Try again.'**
  String get unlockFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'so'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'so':
      return AppLocalizationsSo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
