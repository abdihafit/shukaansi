// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get authLoading => 'Please wait…';

  @override
  String get authRejected =>
      'Unable to complete this request. Check your details and try again.';

  @override
  String get authNetworkError =>
      'Connection unavailable. Check your internet and try again.';

  @override
  String get authThrottled =>
      'Too many attempts. Please wait before trying again.';

  @override
  String get authUnknownError => 'Something went wrong. Please try again.';

  @override
  String get authRequestCompleted => 'Account request completed.';

  @override
  String get appTitle => 'Shukaansi';

  @override
  String get tagline => 'Halal • Serious • Together';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseLanguageSomali => 'Dooro luqaddaada';

  @override
  String get englishLanguage => 'English';

  @override
  String get somaliLanguage => 'Soomaali';

  @override
  String get welcomeTitle => 'Assalamu alaikum, welcome to Shukaansi';

  @override
  String get selectedLanguage => 'Language selected: English';

  @override
  String get getStarted => 'Get Started';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get authIntroduction => 'Your next step toward marriage';

  @override
  String get authPreviewNotice =>
      'Account services are not available yet. These forms do not create an account or sign you in.';

  @override
  String get authUnavailable =>
      'Account services are unavailable. Please try again later.';

  @override
  String get emailAddress => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get passwordGuidance => 'Use at least 6 characters.';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get needAccount => 'New to Shukaansi? Create an account';

  @override
  String get sessionFailed => 'Unable to check your session.';

  @override
  String get retry => 'Try again';

  @override
  String get accountSignedIn => 'You are signed in';

  @override
  String get signOutFailed => 'Unable to sign out. Please try again.';

  @override
  String get signOut => 'Sign out';

  @override
  String get accountStageNotice =>
      'Your account session is active. Profiles and introductions are not available yet. Signing in does not verify your identity.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordIntroduction => 'Reset your password';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get resetPasswordConfirmation =>
      'If an account can receive a reset email at this address, a link will be sent. Check your inbox and spam folder, then return to sign in. The email may be in English.';

  @override
  String get profileAboutHint =>
      'Describe what matters to you in marriage. Do not include contact details or sensitive private information.';

  @override
  String get profileAdultDeclaration => 'I confirm that I am 18 or older.';

  @override
  String get profileFemale => 'Woman';

  @override
  String profileTextLength(int min, int max) {
    return 'Enter between $min and $max characters.';
  }

  @override
  String get profileLoading => 'Checking your profile';

  @override
  String get profileDivorced => 'Divorced';

  @override
  String get profileLocationNotice =>
      'Enter your city only, not your street address.';

  @override
  String get profileReview => 'Review your profile';

  @override
  String get profileSave => 'Create profile';

  @override
  String get profileSaveFailed =>
      'Your profile could not be saved. Your entries are still here. Check your connection and try again.';

  @override
  String get profileWidowed => 'Widowed';

  @override
  String get profileMaritalStatus => 'Marital status';

  @override
  String get profileAbout => 'About you and your marriage intentions';

  @override
  String profileStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get profileCity => 'City';

  @override
  String get profileNeverMarried => 'Never married';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileBack => 'Back';

  @override
  String get profilePrivacyNotice =>
      'Build a respectful introduction. Your profile is private to you at this stage.';

  @override
  String get profileAdultRequired =>
      'You must be 18 or older to create a Shukaansi profile.';

  @override
  String get profileName => 'Profile name';

  @override
  String get profileCreated => 'MashaAllah, your profile is saved';

  @override
  String get profileContinue => 'Continue';

  @override
  String get profileMale => 'Man';

  @override
  String get profileCreatedNotice =>
      'Only you can view this profile for now. Introductions are not available yet. This does not verify your identity.';

  @override
  String get profileLoadFailed =>
      'Your profile could not be loaded. Check your connection and try again. Profile services may not be available yet.';

  @override
  String get profileStepBasicsTitle => 'Let\'s start with you';

  @override
  String get profileStepBasicsHint =>
      'The essentials every introduction begins with.';

  @override
  String get profileStepRootsTitle => 'Your roots';

  @override
  String get profileStepRootsHint => 'Tell us where your family story begins.';

  @override
  String get profileStepHomeTitle => 'Where you live today';

  @override
  String get profileStepPhoneTitle => 'Your phone number';

  @override
  String get profileStepPhoneHint =>
      'Private to you. It is never shown on your profile.';

  @override
  String get profileStepWorkTitle => 'Work and study';

  @override
  String get profileStepWorkHint =>
      'Share what you do and how far you have studied.';

  @override
  String get profileStepFaithTitle => 'Faith and family';

  @override
  String get profileStepFaithHint =>
      'There is no wrong answer. Honest answers help the right person find you.';

  @override
  String get profileStepIntentionsTitle => 'Your marriage intentions';

  @override
  String get profileStepIntentionsHint =>
      'Clear intentions make for respectful introductions.';

  @override
  String get profileStepAboutTitle => 'In your own words';

  @override
  String get profileStepReviewHint => 'Check your answers before saving.';

  @override
  String get profileUpdateNotice =>
      'We have added new questions. Your earlier answers are already filled in.';

  @override
  String get profileUpdateSave => 'Update profile';

  @override
  String get profileDateOfBirth => 'Date of birth';

  @override
  String get profileDateOfBirthHint =>
      'Private. Used to confirm you are 18 or older.';

  @override
  String get profileSelectDate => 'Select your date of birth';

  @override
  String get profileNationality => 'Nationality';

  @override
  String get profileResidence => 'Country you live in';

  @override
  String get profileEthnicity => 'Ethnicity';

  @override
  String get profileEthnicityOtherLabel => 'Your ethnicity';

  @override
  String get profilePhone => 'Phone number';

  @override
  String get profileCountryCode => 'Country code';

  @override
  String get profilePhoneInvalid =>
      'Enter a valid phone number without the country code.';

  @override
  String get profileProfession => 'Profession';

  @override
  String get profileProfessionOtherLabel => 'Your profession';

  @override
  String get profileEducation => 'Highest education';

  @override
  String get profilePractice => 'Your religious practice';

  @override
  String get profileTimeline => 'When do you hope to marry?';

  @override
  String get profileRelocation => 'Open to moving for marriage?';

  @override
  String get profileSearch => 'Search';

  @override
  String get profileSuggested => 'Common choices';

  @override
  String get profileAllOptions => 'All options';

  @override
  String get profileNoResults => 'No matches found';

  @override
  String get profileSelect => 'Select';

  @override
  String get profileSectionPublic => 'Your profile';

  @override
  String get profileSectionPrivate => 'Private to you';

  @override
  String get profileSelected => 'Selected';

  @override
  String get ethnicitySomali => 'Somali Muslim';

  @override
  String get ethnicityArab => 'Arab Muslim';

  @override
  String get ethnicityOther => 'Other Muslim background';

  @override
  String get practiceStrict => 'Very practising';

  @override
  String get practiceStrictInfo =>
      'Prayer, fasting and Islamic guidance shape my daily life.';

  @override
  String get practiceActive => 'Practising';

  @override
  String get practiceActiveInfo =>
      'I make regular practice part of my routine where I can.';

  @override
  String get practiceGrowing => 'Growing in faith';

  @override
  String get practiceGrowingInfo =>
      'I am learning and working on becoming more consistent.';

  @override
  String get practiceCultural => 'Culturally Muslim';

  @override
  String get practiceCulturalInfo =>
      'Islam is part of my identity, though I practise less often.';

  @override
  String get timelineSoon => 'As soon as the right person comes';

  @override
  String get timelineWithinYear => 'Within a year';

  @override
  String get timelineOneToTwoYears => 'In 1–2 years';

  @override
  String get timelineMoreThanTwoYears => 'In more than 2 years';

  @override
  String get relocationYes => 'Yes, I would relocate';

  @override
  String get relocationOpen => 'Open to discussing it';

  @override
  String get relocationNo => 'No, I plan to stay where I am';

  @override
  String get educationSecondary => 'Secondary school';

  @override
  String get educationDiploma => 'Diploma or vocational training';

  @override
  String get educationBachelors => 'Bachelor\'s degree';

  @override
  String get educationMasters => 'Master\'s degree';

  @override
  String get educationDoctorate => 'Doctorate (PhD)';

  @override
  String get educationIslamicStudies => 'Islamic studies qualification';

  @override
  String get optionOther => 'Other';

  @override
  String get professionAccountant => 'Accountant';

  @override
  String get professionArchitect => 'Architect';

  @override
  String get professionBankingFinance => 'Banking and finance';

  @override
  String get professionBusinessOwner => 'Business owner';

  @override
  String get professionChef => 'Chef or catering';

  @override
  String get professionCivilServant => 'Civil servant';

  @override
  String get professionConstructionTrades => 'Construction and trades';

  @override
  String get professionCustomerService => 'Customer service';

  @override
  String get professionDentist => 'Dentist';

  @override
  String get professionDesignerCreative => 'Designer or creative';

  @override
  String get professionDoctor => 'Doctor';

  @override
  String get professionDriverTransport => 'Driver or transport';

  @override
  String get professionElectrician => 'Electrician';

  @override
  String get professionEngineer => 'Engineer';

  @override
  String get professionFarmerAgriculture => 'Farming and agriculture';

  @override
  String get professionHealthcareAssistant => 'Care or healthcare assistant';

  @override
  String get professionHomemaker => 'Homemaker';

  @override
  String get professionHospitality => 'Hospitality';

  @override
  String get professionHumanResources => 'Human resources';

  @override
  String get professionImamIslamicScholar => 'Imam or Islamic scholar';

  @override
  String get professionItSoftware => 'IT and software';

  @override
  String get professionJournalistMedia => 'Journalism and media';

  @override
  String get professionLawyer => 'Lawyer';

  @override
  String get professionLecturer => 'Lecturer or academic';

  @override
  String get professionLogistics => 'Logistics and supply chain';

  @override
  String get professionMarketingSales => 'Marketing and sales';

  @override
  String get professionMechanic => 'Mechanic';

  @override
  String get professionMilitaryDefence => 'Military and defence';

  @override
  String get professionNgoHumanitarian => 'NGO or humanitarian work';

  @override
  String get professionNurse => 'Nurse';

  @override
  String get professionPharmacist => 'Pharmacist';

  @override
  String get professionPilotAviation => 'Pilot or aviation';

  @override
  String get professionPoliceSecurity => 'Police or security';

  @override
  String get professionProjectManager => 'Project manager';

  @override
  String get professionPsychologistCounsellor => 'Psychologist or counsellor';

  @override
  String get professionRealEstate => 'Real estate';

  @override
  String get professionResearcherScientist => 'Researcher or scientist';

  @override
  String get professionRetail => 'Retail';

  @override
  String get professionSocialWorker => 'Social worker';

  @override
  String get professionStudent => 'Student';

  @override
  String get professionTeacher => 'Teacher';

  @override
  String get professionTranslatorInterpreter => 'Translator or interpreter';

  @override
  String get professionLookingForWork => 'Looking for work';

  @override
  String get professionRetired => 'Retired';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profileCancelEdit => 'Cancel';

  @override
  String get profileLockedNotice =>
      'Gender and date of birth cannot be changed after your profile is created.';

  @override
  String get profileUpdated => 'Alhamdulillah, your changes are saved.';

  @override
  String get emailVerifyTitle => 'Verify your email';

  @override
  String emailVerifyBody(String email) {
    return 'We sent a verification link to $email. A verified email will be required before you can meet other members.';
  }

  @override
  String get emailVerifyCheck => 'I\'ve verified it';

  @override
  String get emailVerifyResend => 'Resend email';

  @override
  String get emailVerifySent =>
      'Verification email sent. Check your inbox and spam folder.';

  @override
  String get emailVerifyNotYet =>
      'Not verified yet. Open the link in the email, then try again.';

  @override
  String get emailVerified => 'Email verified';

  @override
  String get accountActionFailed =>
      'Something went wrong. Check your connection and try again.';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteTitle => 'Delete your account';

  @override
  String get accountDeleteBody =>
      'This permanently deletes your Shukaansi profile, your private details and your sign-in account. It cannot be undone.';

  @override
  String get accountDeletePassword => 'Enter your password to confirm';

  @override
  String get accountDeleteConfirm => 'I understand this is permanent';

  @override
  String get accountDeleteConfirmRequired =>
      'Please confirm that you understand.';

  @override
  String get accountDeleteButton => 'Delete my account permanently';

  @override
  String get accountDeleteWrongPassword => 'That password is not correct.';

  @override
  String get accountDeleteFailed =>
      'Your account could not be deleted. Nothing was removed. Check your connection and try again.';

  @override
  String get accountDeletePartial =>
      'Your profile was deleted, but your sign-in account was not. Try again to finish.';

  @override
  String get photosTitle => 'Your photos';

  @override
  String get photosHint =>
      'Add up to 6 photos. Your first photo is your main photo. Only you can see them for now.';

  @override
  String get photosAdd => 'Add photo';

  @override
  String get photosMain => 'Main';

  @override
  String get photosMakeMain => 'Make main photo';

  @override
  String get photosRemove => 'Remove photo';

  @override
  String get photosView => 'View photo';

  @override
  String get photosUploading => 'Uploading photo';

  @override
  String get photosUploadFailed =>
      'The photo could not be uploaded. Check your connection and try again.';

  @override
  String get photosUnsupported =>
      'Choose a JPEG, PNG or WebP photo. Very large photos cannot be used.';

  @override
  String get photosUpdateFailed =>
      'Your photos could not be updated. Try again.';

  @override
  String get photosLoadFailed => 'Your photos could not be loaded.';

  @override
  String get photosPickFailed =>
      'Your photos could not be opened. Check photo permission in your phone settings.';

  @override
  String photosSlot(int number) {
    return 'Photo $number';
  }

  @override
  String get verifyTitle => 'Get verified';

  @override
  String get verifyBody =>
      'Take a selfie so our team can confirm you match your photos. Verified profiles earn more trust from members and their families.';

  @override
  String get verifyStart => 'Start verification';

  @override
  String get verifyNeedsPhoto => 'Add at least one photo first.';

  @override
  String get verifyPendingTitle => 'Verification in review';

  @override
  String get verifyPendingBody =>
      'Our team will review your selfie soon, InshaAllah. The result will appear here.';

  @override
  String get verifyVerified => 'MashaAllah, your profile is verified';

  @override
  String get verifyRejectedTitle => 'Verification not approved';

  @override
  String get verifyRejectedBody =>
      'Your selfie could not be matched to your photos. Check the tips and try again.';

  @override
  String verifyReviewNote(String note) {
    return 'Reviewer note: $note';
  }

  @override
  String get verifyScreenTitle => 'Verify your profile';

  @override
  String get verifyTipsIntro => 'For a quick review:';

  @override
  String get verifyTipLight => 'Use good light and face the camera.';

  @override
  String get verifyTipFace =>
      'Keep your face clearly visible, without sunglasses or filters.';

  @override
  String get verifyTipPrivate =>
      'Your selfie is private. Only our review team sees it, and it is never shown on your profile.';

  @override
  String get verifyTakeSelfie => 'Take selfie';

  @override
  String get verifyRetake => 'Retake';

  @override
  String get verifySubmit => 'Submit for review';

  @override
  String get verifySubmitting => 'Sending your selfie';

  @override
  String get verifySubmitFailed =>
      'Your selfie could not be sent. Check your connection and try again.';

  @override
  String get verifyCameraFailed =>
      'The camera could not be opened. Check camera permission in your phone settings.';

  @override
  String get verifySelfiePreview => 'Your selfie';

  @override
  String get photosResetTitle => 'Reset verification?';

  @override
  String get photosResetBody =>
      'Your verification is linked to your main photo. Changing your main photo resets it, and you will need to take a new selfie to be verified again.';

  @override
  String get photosResetConfirm => 'Change photo';

  @override
  String get verifyTipNiqab =>
      'If you wear a niqab, please remove it for this selfie only. Your face must be visible for verification. The selfie stays private and is seen only by our review team.';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navProfile => 'My profile';

  @override
  String get discoverNotListedTitle => 'Get ready to be discovered';

  @override
  String get discoverNotListedBody =>
      'Complete these steps to appear in Discover and to see other members.';

  @override
  String get discoverNeedEmail => 'Verify your email address';

  @override
  String get discoverNeedPhoto => 'Add at least one profile photo';

  @override
  String get discoverGoToProfile => 'Go to my profile';

  @override
  String get discoverCheckAgain => 'Check again';

  @override
  String get discoverEmpty =>
      'No profiles match yet. Try widening your filters or check back soon, InshaAllah.';

  @override
  String get discoverLoadFailed =>
      'Profiles could not be loaded. Check your connection and try again.';

  @override
  String get discoverFilters => 'Filters';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Age $min to $max';
  }

  @override
  String get discoverAnyCountry => 'Any country';

  @override
  String get discoverCountry => 'Country they live in';

  @override
  String get discoverApply => 'Show profiles';

  @override
  String get discoverReset => 'Reset';

  @override
  String cardNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String cardLocation(String city, String country) {
    return '$city, $country';
  }

  @override
  String get verifiedBadge => 'Verified profile';

  @override
  String photoOf(int current, int total) {
    return 'Photo $current of $total';
  }

  @override
  String get photosPrivateTitle => 'Photos are private';

  @override
  String get photosPrivateBody =>
      'She shares her photos with members she approves.';

  @override
  String get photosRequest => 'Request photos';

  @override
  String get photosRequested => 'Request sent';

  @override
  String get photosCancelRequest => 'Cancel request';

  @override
  String get photosRequestFailed =>
      'Your request could not be sent. Try again.';

  @override
  String get blurTitle => 'Blur my photos in Discover';

  @override
  String get blurBody =>
      'Members see a blurred version until you approve their request.';

  @override
  String get blurFailed =>
      'Your photo privacy could not be changed. Try again.';

  @override
  String get requestsTitle => 'Photo requests';

  @override
  String get requestsEmpty => 'No requests right now.';

  @override
  String get requestsApprove => 'Approve';

  @override
  String get requestsDecline => 'Decline';

  @override
  String get viewersTitle => 'Can see your photos';

  @override
  String get viewersRemove => 'Remove';

  @override
  String get requestsLoadFailed => 'Requests could not be loaded.';

  @override
  String get filterPractice => 'Religious practice';

  @override
  String get reportAction => 'Report';

  @override
  String get blockAction => 'Block';

  @override
  String cardMoreActions(String name) {
    return 'More options for $name';
  }

  @override
  String reportTitle(String name) {
    return 'Report $name';
  }

  @override
  String reportBody(String name) {
    return 'Tell us what is wrong. Reports are confidential: $name will not know who reported them.';
  }

  @override
  String get reportReasonFakeProfile => 'Fake profile or impersonation';

  @override
  String get reportReasonInappropriatePhotos => 'Inappropriate photos';

  @override
  String get reportReasonHarassment => 'Harassment or disrespect';

  @override
  String get reportReasonScam => 'Scam or asking for money';

  @override
  String get reportReasonUnderage => 'May be under 18';

  @override
  String get reportReasonNotSerious => 'Not serious about marriage';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportNote => 'Details (optional)';

  @override
  String reportAlsoBlock(String name) {
    return 'Also block $name';
  }

  @override
  String get reportSubmit => 'Send report';

  @override
  String get reportSent =>
      'JazakAllahu khayran. Our team will review your report.';

  @override
  String get reportFailed => 'Your report could not be sent. Try again.';

  @override
  String blockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get blockBody =>
      'You will no longer see each other in Discover, and photo permissions between you end. They are not told.';

  @override
  String get blockFailed => 'Could not block. Try again.';

  @override
  String get blockedTitle => 'Blocked members';

  @override
  String get unblockAction => 'Unblock';

  @override
  String get suspendedTitle => 'Your account is suspended';

  @override
  String get suspendedBody =>
      'You cannot use Shukaansi while your account is suspended.';

  @override
  String suspendedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String suspendedContact(String email) {
    return 'To appeal, contact $email.';
  }

  @override
  String stepsDone(int done, int total) {
    return '$done of $total complete';
  }

  @override
  String photosCount(int count, int max) {
    return '$count of $max added';
  }

  @override
  String get verifyStatusNotStarted => 'Not started';

  @override
  String get verifyStatusPending => 'In review';

  @override
  String get verifyStatusRejected => 'Not approved';

  @override
  String get navLikes => 'Likes';

  @override
  String get navMatches => 'Matches';

  @override
  String get navChats => 'Chats';

  @override
  String get matchesSoonBody =>
      'When two members show interest in each other, it becomes a match. Your matches will appear here.';

  @override
  String get browseDiscover => 'Browse Discover';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get legalTitle => 'Before you continue';

  @override
  String get legalBody =>
      'Please read our Terms of Use and Privacy Policy. They follow Islamic manners and explain how we protect your information.';

  @override
  String get legalTermsPoint =>
      'Seeking marriage with honesty, modesty and respect.';

  @override
  String get legalPrivacyPoint =>
      'Your data is never sold or shared with advertisers.';

  @override
  String get legalAgree =>
      'I have read and agree to the Terms of Use and Privacy Policy.';

  @override
  String get legalContinue => 'Agree and continue';

  @override
  String get legalSaveFailed =>
      'We couldn\'t save your agreement. Check your connection and try again.';

  @override
  String get legalCheckFailed =>
      'We couldn\'t check your account. Check your connection and try again.';

  @override
  String get legalLoadFailed => 'This document couldn\'t be opened.';

  @override
  String get verifyStepPhoto => 'Photo';

  @override
  String get verifyStepSelfie => 'Selfie';

  @override
  String get verifyStepReview => 'Review';

  @override
  String get stepStateDone => 'done';

  @override
  String get stepStateCurrent => 'in progress';

  @override
  String get stepStateUpcoming => 'next';

  @override
  String get verifyHeadline => 'Confirm it\'s you';

  @override
  String get verifyIntro =>
      'Take a quick selfie so our team can compare it with your main photo.';

  @override
  String get verifyPrivateTitle => 'Private and secure';

  @override
  String get verifyCareTitle => 'Reviewed with care';

  @override
  String get verifyCareBody =>
      'We use it only to confirm that it\'s really you.';

  @override
  String get verifyCheckHeadline => 'Check your selfie';

  @override
  String get verifyCheckBody =>
      'Make sure your face is clear and well lit, then send it for review.';

  @override
  String get verifySubmittedChip => 'Selfie submitted';

  @override
  String get verifySubmittedTitle => 'Your verification is in review';

  @override
  String get verifySubmittedBody =>
      'JazakAllahu khayran. Our team will compare your selfie with your main photo and let you know here, InshaAllah.';

  @override
  String get reviewStepProfile => 'Profile completed';

  @override
  String get reviewStepProfileBody => 'Your details and photos are saved.';

  @override
  String get reviewStepReview => 'Verification review';

  @override
  String get reviewStepReviewBody => 'Our team checks every selfie by hand.';

  @override
  String get reviewStepBadge => 'Verified badge';

  @override
  String get reviewStepBadgeBody =>
      'Once approved, your profile shows the blue verified badge, InshaAllah.';

  @override
  String get verifyContinue => 'Continue to Shukaansi';

  @override
  String get likeAction => 'Show interest';

  @override
  String get withdrawInterest => 'Withdraw interest';

  @override
  String get matchedLabel => 'Matched';

  @override
  String likeSent(String name) {
    return 'Alhamdulillah, your interest was sent to $name.';
  }

  @override
  String get interestFailed =>
      'That didn\'t work. Check your connection and try again.';

  @override
  String get matchTitle => 'MashaAllah, it\'s a match!';

  @override
  String matchBody(String name) {
    return 'You and $name have both shown interest. May Allah put khayr in it.';
  }

  @override
  String get matchPhotosNote => 'You can now see each other\'s photos.';

  @override
  String get matchMessagingSoon => 'Messaging opens soon, InshaAllah.';

  @override
  String get viewMatches => 'View matches';

  @override
  String get keepBrowsing => 'Keep browsing';

  @override
  String get likesReceivedTab => 'Liked you';

  @override
  String get likesSentTab => 'You liked';

  @override
  String get likesReceivedEmpty =>
      'No one has shown interest yet. Keep your profile complete and check back soon, InshaAllah.';

  @override
  String get likesSentEmpty =>
      'You haven\'t shown interest in anyone yet. Tap the heart on a profile in Discover.';

  @override
  String get likeBack => 'Like back';

  @override
  String get declineInterest => 'Not for me';

  @override
  String get likesLoadFailed => 'Likes could not be loaded.';

  @override
  String get matchesEmptyTitle => 'No matches yet';

  @override
  String get matchesLoadFailed => 'Matches could not be loaded.';

  @override
  String get unmatch => 'Unmatch';

  @override
  String unmatchTitle(String name) {
    return 'Unmatch $name?';
  }

  @override
  String get unmatchBody =>
      'You will no longer be matched and photo sharing between you ends. You would both need to show interest again to match.';

  @override
  String get viewProfile => 'View profile';

  @override
  String likesNewCount(int count) {
    return '$count new';
  }

  @override
  String get discoverForYou => 'For you';

  @override
  String get discoverNewMembers => 'New members';

  @override
  String get forYouSubtitle => 'Members who suit your partner preferences.';

  @override
  String get newMembersSubtitle => 'The newest members, most recent first.';

  @override
  String get forYouSetupTitle => 'Tell us who you\'re looking for';

  @override
  String get forYouSetupBody =>
      'Set your partner preferences and we\'ll show you members who suit them, InshaAllah.';

  @override
  String get setPreferences => 'Set preferences';

  @override
  String get partnerPreferences => 'Partner preferences';

  @override
  String get prefCountries => 'Countries they live in';

  @override
  String get prefCountriesHint =>
      'Leave empty for any country. Choose up to 10.';

  @override
  String get prefAddCountry => 'Add country';

  @override
  String prefRemoveCountry(String country) {
    return 'Remove $country';
  }

  @override
  String get prefSave => 'Save preferences';

  @override
  String get prefSaved => 'Alhamdulillah, your preferences are saved.';

  @override
  String get prefSaveFailed =>
      'Your preferences could not be saved. Try again.';

  @override
  String get prefNotSet => 'Not set yet';

  @override
  String prefAges(int min, int max) {
    return 'Ages $min–$max';
  }

  @override
  String prefCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count countries',
      one: '1 country',
    );
    return '$_temp0';
  }

  @override
  String get prefAnyAnswer => 'Any';

  @override
  String get roleTitle => 'How will you use Shukaansi?';

  @override
  String get roleMember => 'I\'m looking for a spouse';

  @override
  String get roleMemberBody =>
      'Create your profile and meet Muslims seeking marriage.';

  @override
  String get roleWali => 'I\'m a Wali';

  @override
  String get roleWaliBody =>
      'A family member invited you to approve their matches.';

  @override
  String get waliSetupTitle => 'Join as a Wali';

  @override
  String get waliSetupBody =>
      'Enter your name and the code your family member shared with you.';

  @override
  String get waliYourName => 'Your name';

  @override
  String get waliCode => 'Invite code';

  @override
  String get waliJoin => 'Join';

  @override
  String get waliCodeInvalid =>
      'This code isn\'t valid or has expired. Ask for a new one.';

  @override
  String get waliHomeTitle => 'Wali';

  @override
  String waliGreeting(String name) {
    return 'Assalamu alaikum, $name';
  }

  @override
  String waliGuarding(String names) {
    return 'You are the Wali for $names.';
  }

  @override
  String get waliNoMembers =>
      'You aren\'t the Wali for anyone yet. Ask your family member for an invite code.';

  @override
  String get waliAddMember => 'Enter another code';

  @override
  String get waliRequestsTitle => 'Match requests';

  @override
  String get waliNoRequests =>
      'No match requests yet. You\'ll be asked here when there is a new match, InshaAllah.';

  @override
  String waliRequestFor(String name) {
    return 'Match for $name';
  }

  @override
  String get waliApprove => 'Approve';

  @override
  String get waliDecline => 'Decline';

  @override
  String get waliApproved =>
      'MashaAllah, you approved this match. May Allah make it a blessing.';

  @override
  String get waliDeclined => 'You declined this match.';

  @override
  String get waliDeclineTitle => 'Decline this match?';

  @override
  String get waliDeclineBody =>
      'Both members will see that the match was declined, and they will not be able to message each other.';

  @override
  String get waliStatusApproved => 'Approved';

  @override
  String get waliStatusDeclined => 'Declined';

  @override
  String get waliStatusWaiting => 'Waiting for you';

  @override
  String waliStop(String name) {
    return 'Stop being Wali for $name';
  }

  @override
  String waliStopTitle(String name) {
    return 'Stop being Wali for $name?';
  }

  @override
  String waliStopBody(String name) {
    return '$name will need to invite a new Wali.';
  }

  @override
  String get waliPhotosNote =>
      'Photos are shared only between the two members.';

  @override
  String get waliLoadFailed => 'This couldn\'t be loaded.';

  @override
  String get waliCardTitle => 'Your Wali';

  @override
  String get waliRequiredBody =>
      'Required for sisters: your matches can message only after your Wali approves.';

  @override
  String get waliOptionalBody =>
      'Optional: add a Wali to approve your matches before messaging.';

  @override
  String get waliRequiredChip => 'Required';

  @override
  String get waliInvite => 'Invite your Wali';

  @override
  String get waliInviteCode => 'Invite code';

  @override
  String waliInviteExpires(String date) {
    return 'Valid until $date';
  }

  @override
  String get waliShareCode => 'Share code';

  @override
  String get waliCopyCode => 'Copy code';

  @override
  String get waliCopied => 'Code copied';

  @override
  String get waliNewCode => 'New code';

  @override
  String waliShareMessage(String code) {
    return 'Assalamu alaikum. Please be my Wali on Shukaansi. Install the app, choose \"I\'m a Wali\" and enter this code: $code. It is valid for 7 days.';
  }

  @override
  String waliLinked(String name) {
    return '$name is your Wali';
  }

  @override
  String get waliLinkedBody =>
      'Your Wali approves your matches before you can message.';

  @override
  String get waliRemove => 'Remove Wali';

  @override
  String waliRemoveTitle(String name) {
    return 'Remove $name as your Wali?';
  }

  @override
  String get waliRemoveBody =>
      'Their approvals are cleared, and a new Wali will need to approve your matches again.';

  @override
  String get approvalNeedsWali => 'Add your Wali to continue';

  @override
  String get approvalWaitingYours => 'Waiting for your Wali\'s approval';

  @override
  String get approvalWaitingTheirs => 'Waiting for their Wali\'s approval';

  @override
  String get approvalDeclined => 'A Wali declined this match';

  @override
  String get chatsActive => 'Conversations';

  @override
  String get chatsNewMatches => 'New matches';

  @override
  String get chatsNewMatchesBody =>
      'Say salaam and start a respectful conversation.';

  @override
  String get chatsEmptyTitle => 'No conversations yet';

  @override
  String get chatsEmptyBody =>
      'When you both show interest, your match will appear here, InshaAllah.';

  @override
  String get viewMatchesAction => 'View matches';

  @override
  String get chatsLoadFailed => 'Conversations could not be loaded.';

  @override
  String get messageAction => 'Message';

  @override
  String get messageHint => 'Write a message';

  @override
  String get messageSend => 'Send';

  @override
  String get messageSendFailed => 'Your message could not be sent. Try again.';

  @override
  String get chatStarterTitle => 'Begin with salaam';

  @override
  String get chatStarterBody =>
      'Keep the conversation respectful and focused on marriage. Involve your families when the time is right.';

  @override
  String get chatStarterSalaam => 'Assalamu alaikum';

  @override
  String get chatLocked =>
      'Messaging opens once the required Wali approval is given.';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatUnread => 'New message';

  @override
  String chatYou(String text) {
    return 'You: $text';
  }

  @override
  String chatsUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get messageFromYou => 'You said';

  @override
  String messageFrom(String name) {
    return '$name said';
  }

  @override
  String get activityTitle => 'Notifications';

  @override
  String get activityEmpty =>
      'You\'re all caught up. New interest, matches and messages will appear here, InshaAllah.';

  @override
  String get activityOpenOnly =>
      'Alerts appear while Shukaansi is open. Phone notifications when the app is closed are coming soon.';

  @override
  String activityLiked(String name) {
    return '$name showed interest in you';
  }

  @override
  String activityMatched(String name) {
    return 'MashaAllah, you matched with $name';
  }

  @override
  String activityYourWaliApproved(String name) {
    return 'Your Wali approved your match with $name';
  }

  @override
  String activityYourWaliDeclined(String name) {
    return 'Your Wali declined your match with $name';
  }

  @override
  String activityTheirWaliApproved(String name) {
    return '$name\'s Wali approved your match. You can now message, InshaAllah.';
  }

  @override
  String activityTheirWaliDeclined(String name) {
    return '$name\'s Wali declined the match';
  }

  @override
  String activityMessage(String name) {
    return 'New message from $name';
  }

  @override
  String get activityView => 'View';

  @override
  String get activityNew => 'New';

  @override
  String get mutualTitle => 'MashaAllah, you both like each other';

  @override
  String get mutualBody =>
      'A match needs Premium on either side. When either of you upgrades, the match is made, InshaAllah.';

  @override
  String get mutualNeedsPremium =>
      'You both like each other: Premium needed to match';

  @override
  String get viewPlans => 'View plans';

  @override
  String get plansTitle => 'Choose your plan';

  @override
  String get planFree => 'Free';

  @override
  String get planPremium => 'Premium';

  @override
  String get planVip => 'VIP';

  @override
  String get planHeadlineFree => 'Begin your search';

  @override
  String get planHeadlinePremium => 'Meet with more choice';

  @override
  String get planHeadlineVip => 'Be seen first';

  @override
  String get planSubFree => 'Everything you need to start, at no cost.';

  @override
  String get planSubPremium =>
      'Match with anyone you both like, and message your matches.';

  @override
  String get planSubVip =>
      'Everything in Premium, with priority placement in Discover.';

  @override
  String get featureProfile => 'Create your profile and get verified';

  @override
  String get featureBrowse => 'Browse Discover and show interest';

  @override
  String get featureMatchPremium => 'Match with members who have Premium';

  @override
  String get featureMatchAnyone => 'Match with anyone you both like';

  @override
  String get featureMessage => 'Message your matches, with Wali approval';

  @override
  String get featurePriority => 'Shown first in Discover';

  @override
  String get featureEverythingPremium => 'Everything in Premium';

  @override
  String get perMonth => '/ month';

  @override
  String get planCancelAnytime => 'Cancel anytime.';

  @override
  String planContinue(String plan) {
    return 'Continue with $plan';
  }

  @override
  String get planCurrent => 'Your current plan';

  @override
  String get planComingSoonTitle => 'Coming soon, InshaAllah';

  @override
  String get planComingSoonBody =>
      'Subscriptions through Google Play are on the way. Until then, our team can add Premium or VIP to your account.';

  @override
  String get planRenewNote =>
      'When available, subscriptions renew automatically unless cancelled.';

  @override
  String get compareAllPlans => 'Compare all plans';

  @override
  String get membershipTitle => 'My membership';

  @override
  String get membershipFreeBody => 'Explore Shukaansi with essential features.';

  @override
  String membershipActive(String plan, String date) {
    return '$plan until $date';
  }

  @override
  String get previewBadge => 'Preview · fictional profiles';

  @override
  String get previewScenarios => 'Preview scenarios';

  @override
  String get previewScenariosBody =>
      'Everything here is simulated on this device. Nothing is sent to Shukaansi.';

  @override
  String get scenarioPopulated => 'Members to discover';

  @override
  String get scenarioPrefsNotSet => 'Preferences not set';

  @override
  String get scenarioNoMatches => 'No matching profiles';

  @override
  String get scenarioLoading => 'Loading';

  @override
  String get scenarioNetworkError => 'Network failure';

  @override
  String get scenarioIncomplete => 'Incomplete profile';

  @override
  String get scenarioAwaitingReview => 'Verification in review';

  @override
  String get scenarioEmptyActivity => 'No likes or conversations';

  @override
  String get previewSimulatePremium => 'Simulate Premium for this account';

  @override
  String get previewNotAvailable =>
      'This action isn\'t available in the preview.';

  @override
  String get previewDisabledTitle => 'Preview is turned off';

  @override
  String get previewDisabledBody =>
      'Run a debug or profile build with --dart-define=SHUKAANSI_PREVIEW=true.';

  @override
  String get photoVerified => 'Photo verified';

  @override
  String get photoVerifiedInfo =>
      'Our team compared a private selfie with this member\'s photos. It does not confirm identity documents.';

  @override
  String aboutName(String name) {
    return 'About $name';
  }

  @override
  String marriagePlans(String timeline) {
    return 'Marriage plans: $timeline';
  }

  @override
  String get sectionBackground => 'Background';

  @override
  String get factLivesIn => 'Lives in';

  @override
  String get factPractice => 'Religious practice';

  @override
  String get factRelocation => 'Open to relocating';

  @override
  String get conceptLabel => 'Concept';

  @override
  String get interestsTitle => 'Interests';

  @override
  String get photoLoadFailed => 'This photo couldn\'t load.';

  @override
  String get closePhoto => 'Close photo';

  @override
  String openPhoto(int current, int total) {
    return 'Open photo $current of $total';
  }

  @override
  String get passAction => 'Pass';

  @override
  String passedName(String name) {
    return 'You passed on $name';
  }

  @override
  String get undoAction => 'Undo';

  @override
  String get seenEveryoneTitle => 'You\'ve seen everyone for now';

  @override
  String get seenEveryoneBody =>
      'New members join regularly. Check again later, InshaAllah.';

  @override
  String get noMatchesTitle => 'No members match your preferences';

  @override
  String get noMatchesBody => 'Try a wider age range or more countries.';

  @override
  String get adjustPreferences => 'Adjust preferences';

  @override
  String get networkErrorTitle => 'Couldn\'t connect';

  @override
  String get networkErrorBody =>
      'Check your internet connection and try again.';

  @override
  String get newMembersEmpty =>
      'No new members yet. Check again soon, InshaAllah.';

  @override
  String get likeStatusLikesYou => 'Likes you';

  @override
  String get likeStatusWaiting => 'Waiting for a reply';

  @override
  String get likeStatusMutual => 'You both like each other';

  @override
  String get profileProgressTitle => 'Your progress';

  @override
  String get progressAccount => 'Account';

  @override
  String get progressAccountTodo => 'Verify your email';

  @override
  String get progressProfile => 'Profile';

  @override
  String get progressVisible => 'Visible in Discover';

  @override
  String get progressAddPhoto => 'Add a photo to appear in Discover';

  @override
  String get progressVerification => 'Photo verification';

  @override
  String get verifyStatusVerified => 'Verified';

  @override
  String get previewProfile => 'Preview profile';

  @override
  String get managePhotos => 'Manage photos';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get yourPlans => 'Plans and preferences';

  @override
  String get profilePrivateDetails =>
      'All your answers, including private details';

  @override
  String get chatsStartHint =>
      'Tap a new match to see their profile and say salaam.';

  @override
  String get loadingSlow => 'Taking longer than usual?';

  @override
  String profileComplete(int percent) {
    return '$percent% complete';
  }

  @override
  String get verifyNudgeTitle => 'Verify your photo to get more trust';

  @override
  String get verifyNudgeBody =>
      'Members and families trust verified profiles more. It only takes a quick selfie.';

  @override
  String get appLockTitle => 'Unlock with fingerprint, face or PIN';

  @override
  String get appLockSubtitle =>
      'Asks when Shukaansi opens, or after 5 minutes away';

  @override
  String get appLockReason => 'Unlock Shukaansi';

  @override
  String get appLockEnableReason => 'Confirm it\'s you to turn on app lock';

  @override
  String get appLockOn => 'MashaAllah, app lock is on';

  @override
  String get appLockUnavailable =>
      'Set up a fingerprint, face or screen lock on your phone first.';

  @override
  String get lockedTitle => 'Shukaansi is locked';

  @override
  String get lockedBody =>
      'Use your fingerprint, face or phone PIN to continue.';

  @override
  String get unlockAction => 'Unlock';

  @override
  String get unlockFailed => 'Could not unlock. Try again.';
}
