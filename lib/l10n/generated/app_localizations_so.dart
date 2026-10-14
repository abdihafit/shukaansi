// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Somali (`so`).
class AppLocalizationsSo extends AppLocalizations {
  AppLocalizationsSo([String locale = 'so']) : super(locale);

  @override
  String get authLoading => 'Fadlan sug…';

  @override
  String get authRejected =>
      'Codsigan lama dhammaystiri karin. Hubi xogtaada oo isku day mar kale.';

  @override
  String get authNetworkError =>
      'Xiriir lama heli karo. Hubi internetkaaga oo isku day mar kale.';

  @override
  String get authThrottled =>
      'Isku dayo badan. Fadlan sug ka hor intaadan mar kale isku dayin.';

  @override
  String get authUnknownError => 'Wax baa khaldamay. Fadlan isku day mar kale.';

  @override
  String get authRequestCompleted => 'Codsiga akoonka waa la dhammaystiray.';

  @override
  String get appTitle => 'Shukaansi';

  @override
  String get tagline => 'Xalaal • Dhab ah • Wadajir';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseLanguageSomali => 'Dooro luqaddaada';

  @override
  String get englishLanguage => 'English';

  @override
  String get somaliLanguage => 'Soomaali';

  @override
  String get welcomeTitle => 'Assalaamu calaykum, ku soo dhawoow Shukaansi';

  @override
  String get selectedLanguage => 'Luqadda la doortay: Soomaali';

  @override
  String get getStarted => 'Bilow';

  @override
  String get createAccount => 'Samee akoon';

  @override
  String get signIn => 'Soo gal';

  @override
  String get authIntroduction => 'Tallaabadaada xigta ee guurka';

  @override
  String get authPreviewNotice =>
      'Adeegyada akoonka weli diyaar ma aha. Foomamkani ma abuuraan akoon, kumana geliyaan.';

  @override
  String get authUnavailable =>
      'Adeegyada akoonka lama heli karo. Fadlan mar dambe isku day.';

  @override
  String get emailAddress => 'Cinwaanka iimaylka';

  @override
  String get password => 'Furaha sirta';

  @override
  String get confirmPassword => 'Xaqiiji furaha sirta';

  @override
  String get showPassword => 'Muuji furaha sirta';

  @override
  String get hidePassword => 'Qari furaha sirta';

  @override
  String get fieldRequired => 'Goobtan waa loo baahan yahay.';

  @override
  String get invalidEmail => 'Geli cinwaan iimayl oo sax ah.';

  @override
  String get passwordGuidance => 'Isticmaal ugu yaraan 6 xaraf.';

  @override
  String get passwordMismatch => 'Furayaasha sirta isma waafaqaan.';

  @override
  String get alreadyHaveAccount => 'Akoon ma leedahay? Soo gal';

  @override
  String get needAccount => 'Ku cusub Shukaansi? Samee akoon';

  @override
  String get sessionFailed => 'Lama hubin karo gelitaankaaga.';

  @override
  String get retry => 'Mar kale isku day';

  @override
  String get accountSignedIn => 'Waad soo gashay';

  @override
  String get signOutFailed =>
      'Ka bixiddu ma suuragelin. Fadlan mar kale isku day.';

  @override
  String get signOut => 'Ka bax';

  @override
  String get accountStageNotice =>
      'Waxaad ku jirtaa akoonkaaga. Bogagga shakhsiga iyo isbarashadu weli ma diyaar aha. Soo geliddu ma xaqiijiso aqoonsigaaga.';

  @override
  String get forgotPassword => 'Ma illowday erayga sirta ah?';

  @override
  String get resetPasswordIntroduction => 'Dib u deji eraygaaga sirta ah';

  @override
  String get sendResetLink => 'Dir xiriiriyaha dib-u-dejinta';

  @override
  String get backToSignIn => 'Ku noqo soo gelidda';

  @override
  String get resetPasswordConfirmation =>
      'Haddii akoonku cinwaankan ku heli karo iimayl dib-u-dejin ah, xiriiriye ayaa loo diri doonaa. Hubi iimaylkaaga iyo galka spam, ka dibna ku noqo soo gelidda. Iimaylku wuxuu noqon karaa Ingiriisi.';

  @override
  String get profileAboutHint =>
      'Sharax waxa guurka muhiim kuugu ah. Ha ku darin xogta xiriirka ama xog gaar ah oo xasaasi ah.';

  @override
  String get profileAdultDeclaration =>
      'Waxaan xaqiijinayaa inaan ahay 18 jir ama ka weyn.';

  @override
  String get profileFemale => 'Haweeney';

  @override
  String profileTextLength(int min, int max) {
    return 'Geli inta u dhaxaysa $min iyo $max xaraf.';
  }

  @override
  String get profileLoading => 'Boggaaga ayaa la hubinayaa';

  @override
  String get profileDivorced => 'La furay';

  @override
  String get profileLocationNotice =>
      'Geli magaalada oo keliya, ha gelin cinwaanka gurigaaga.';

  @override
  String get profileReview => 'Dib u eeg boggaaga';

  @override
  String get profileSave => 'Samee bogga';

  @override
  String get profileSaveFailed =>
      'Boggaaga lama kaydin karin. Xogtaadu weli way kuu taal. Hubi xiriirka oo mar kale isku day.';

  @override
  String get profileWidowed => 'Lammaanihii ayaa geeriyooday';

  @override
  String get profileMaritalStatus => 'Xaaladda guurka';

  @override
  String get profileAbout => 'Naftaada iyo ujeeddadaada guurka';

  @override
  String profileStep(int current, int total) {
    return 'Tallaabada $current ee $total';
  }

  @override
  String get profileCity => 'Magaalada';

  @override
  String get profileNeverMarried => 'Weli ma guursan';

  @override
  String get profileGender => 'Jinsiga';

  @override
  String get profileBack => 'Dib u noqo';

  @override
  String get profilePrivacyNotice =>
      'Samee isbarasho xushmad leh. Marxaladdan adiga oo keliya ayaa arki kara boggaaga.';

  @override
  String get profileAdultRequired =>
      'Waa inaad tahay 18 jir ama ka weyn si aad bog Shukaansi u samaysato.';

  @override
  String get profileName => 'Magaca bogga';

  @override
  String get profileCreated => 'Mashaa Allah, boggaaga waa la kaydiyay';

  @override
  String get profileContinue => 'Sii wad';

  @override
  String get profileMale => 'Nin';

  @override
  String get profileCreatedNotice =>
      'Hadda adiga oo keliya ayaa arki kara boggan. Isbarashadu weli ma diyaar aha. Tani ma xaqiijiso aqoonsigaaga.';

  @override
  String get profileLoadFailed =>
      'Boggaaga lama soo bandhigi karo. Hubi xiriirka oo mar kale isku day. Adeegga bogagga waxaa laga yaabaa inuusan weli diyaar ahayn.';

  @override
  String get profileStepBasicsTitle => 'Aan kaga bilowno adiga';

  @override
  String get profileStepBasicsHint =>
      'Waxyaabaha aasaasiga ah ee isbarasho kasta ku bilaabato.';

  @override
  String get profileStepRootsTitle => 'Asalkaaga';

  @override
  String get profileStepRootsHint =>
      'Noo sheeg halka ay ka bilaabato sheekada qoyskaagu.';

  @override
  String get profileStepHomeTitle => 'Halka aad maanta ku nooshahay';

  @override
  String get profileStepPhoneTitle => 'Lambarka taleefankaaga';

  @override
  String get profileStepPhoneHint =>
      'Adiga oo keliya ayaa arka. Weligii laguma muujiyo boggaaga.';

  @override
  String get profileStepWorkTitle => 'Shaqada iyo waxbarashada';

  @override
  String get profileStepWorkHint =>
      'Wadaag waxaad qabato iyo heerka waxbarashadaada.';

  @override
  String get profileStepFaithTitle => 'Diinta iyo qoyska';

  @override
  String get profileStepFaithHint =>
      'Jawaab khalad ah ma jirto. Jawaabo run ah ayaa ka caawiya qofka kuu habboon inuu ku helo.';

  @override
  String get profileStepIntentionsTitle => 'Ujeeddadaada guurka';

  @override
  String get profileStepIntentionsHint =>
      'Ujeeddo cad waxay keentaa isbarasho xushmad leh.';

  @override
  String get profileStepAboutTitle => 'Ereyadaada';

  @override
  String get profileStepReviewHint =>
      'Hubi jawaabahaaga ka hor intaadan kaydin.';

  @override
  String get profileUpdateNotice =>
      'Su\'aalo cusub ayaan ku darnay. Jawaabahaagii hore horey ayaa loo buuxiyay.';

  @override
  String get profileUpdateSave => 'Cusboonaysii bogga';

  @override
  String get profileDateOfBirth => 'Taariikhda dhalashada';

  @override
  String get profileDateOfBirthHint =>
      'Waa gaar. Waxaa loo isticmaalaa in la xaqiijiyo inaad tahay 18 jir ama ka weyn.';

  @override
  String get profileSelectDate => 'Dooro taariikhda dhalashadaada';

  @override
  String get profileNationality => 'Jinsiyadda';

  @override
  String get profileResidence => 'Dalka aad ku nooshahay';

  @override
  String get profileEthnicity => 'Qowmiyadda';

  @override
  String get profileEthnicityOtherLabel => 'Qowmiyaddaada';

  @override
  String get profilePhone => 'Lambarka taleefanka';

  @override
  String get profileCountryCode => 'Koodhka dalka';

  @override
  String get profilePhoneInvalid =>
      'Geli lambar taleefan sax ah adigoon ku darin koodhka dalka.';

  @override
  String get profileProfession => 'Xirfadda';

  @override
  String get profileProfessionOtherLabel => 'Xirfaddaada';

  @override
  String get profileEducation => 'Heerka waxbarasho ee ugu sarreeya';

  @override
  String get profilePractice => 'Dhaqanka diintaada';

  @override
  String get profileTimeline => 'Goorma ayaad rajaynaysaa inaad guursato?';

  @override
  String get profileRelocation =>
      'Ma diyaar u tahay inaad guur awgii u guurto?';

  @override
  String get profileSearch => 'Raadi';

  @override
  String get profileSuggested => 'Doorashooyinka caadiga ah';

  @override
  String get profileAllOptions => 'Dhammaan doorashooyinka';

  @override
  String get profileNoResults => 'Wax la mid ah lama helin';

  @override
  String get profileSelect => 'Dooro';

  @override
  String get profileSectionPublic => 'Boggaaga';

  @override
  String get profileSectionPrivate => 'Adiga oo keliya';

  @override
  String get profileSelected => 'La doortay';

  @override
  String get ethnicitySomali => 'Muslim Soomaali ah';

  @override
  String get ethnicityArab => 'Muslim Carab ah';

  @override
  String get ethnicityOther => 'Asal kale oo Muslim ah';

  @override
  String get practiceStrict => 'Aad u dhaqma';

  @override
  String get practiceStrictInfo =>
      'Salaadda, soonka iyo tilmaamaha Islaamku waxay hagaan noloshayda maalin kasta.';

  @override
  String get practiceActive => 'Dhaqma';

  @override
  String get practiceActiveInfo =>
      'Waxaan isku dayaa in cibaadadu noqoto qayb joogto ah oo noloshayda ka mid ah.';

  @override
  String get practiceGrowing => 'Diinta ku koraya';

  @override
  String get practiceGrowingInfo =>
      'Waan baranayaa oo waxaan ku dadaalayaa inaan noqdo mid joogto ah.';

  @override
  String get practiceCultural => 'Muslim dhaqan ahaan';

  @override
  String get practiceCulturalInfo =>
      'Islaamku waa qayb ka mid ah aqoonsigayga, inkastoo aanan si joogto ah u dhaqmin.';

  @override
  String get timelineSoon => 'Isla marka qofka saxda ahi yimaado';

  @override
  String get timelineWithinYear => 'Sannad gudihiis';

  @override
  String get timelineOneToTwoYears => '1–2 sano gudahood';

  @override
  String get timelineMoreThanTwoYears => 'In ka badan 2 sano';

  @override
  String get relocationYes => 'Haa, waan u guuri lahaa';

  @override
  String get relocationOpen => 'Waan ka wada hadli karnaa';

  @override
  String get relocationNo => 'Maya, meesha aan joogo ayaan sii joogayaa';

  @override
  String get educationSecondary => 'Dugsi sare';

  @override
  String get educationDiploma => 'Dibloom ama tababar xirfadeed';

  @override
  String get educationBachelors => 'Shahaadada koowaad (Bachelor)';

  @override
  String get educationMasters => 'Shahaadada labaad (Master)';

  @override
  String get educationDoctorate => 'Shahaadada dhakhtarnimada (PhD)';

  @override
  String get educationIslamicStudies => 'Shahaado cilmi diimeed';

  @override
  String get optionOther => 'Kale';

  @override
  String get professionAccountant => 'Xisaabiye';

  @override
  String get professionArchitect => 'Naqshadeeye dhismo';

  @override
  String get professionBankingFinance => 'Bangiga iyo maaliyadda';

  @override
  String get professionBusinessOwner => 'Ganacsade';

  @override
  String get professionChef => 'Cunto kariye';

  @override
  String get professionCivilServant => 'Shaqaale dawladeed';

  @override
  String get professionConstructionTrades => 'Dhismaha iyo farsamada gacanta';

  @override
  String get professionCustomerService => 'Adeegga macmiilka';

  @override
  String get professionDentist => 'Dhakhtarka ilkaha';

  @override
  String get professionDesignerCreative => 'Naqshadeeye ama hal-abuur';

  @override
  String get professionDoctor => 'Dhakhtar';

  @override
  String get professionDriverTransport => 'Darawal ama gaadiid';

  @override
  String get professionElectrician => 'Koronto-yaqaan';

  @override
  String get professionEngineer => 'Injineer';

  @override
  String get professionFarmerAgriculture => 'Beeraha iyo xoolaha';

  @override
  String get professionHealthcareAssistant => 'Kaaliye caafimaad ama daryeel';

  @override
  String get professionHomemaker => 'Maamulaha guriga';

  @override
  String get professionHospitality => 'Martigelinta iyo hudheelada';

  @override
  String get professionHumanResources => 'Maamulka shaqaalaha (HR)';

  @override
  String get professionImamIslamicScholar => 'Imaam ama aqoonyahan diimeed';

  @override
  String get professionItSoftware => 'Teknoolajiyada iyo barnaamijyada';

  @override
  String get professionJournalistMedia => 'Saxaafadda iyo warbaahinta';

  @override
  String get professionLawyer => 'Qareen';

  @override
  String get professionLecturer => 'Macallin jaamacadeed';

  @override
  String get professionLogistics => 'Saadka iyo sahayda';

  @override
  String get professionMarketingSales => 'Suuqgeynta iyo iibka';

  @override
  String get professionMechanic => 'Makaanik';

  @override
  String get professionMilitaryDefence => 'Ciidamada iyo difaaca';

  @override
  String get professionNgoHumanitarian => 'Hay\'ad samafal ama gargaar';

  @override
  String get professionNurse => 'Kalkaaliye caafimaad';

  @override
  String get professionPharmacist => 'Farmashiiste';

  @override
  String get professionPilotAviation => 'Duuliye ama duulimaad';

  @override
  String get professionPoliceSecurity => 'Booliis ama amni';

  @override
  String get professionProjectManager => 'Maareeyaha mashruuca';

  @override
  String get professionPsychologistCounsellor =>
      'Cilmi-nafsi yaqaan ama la-taliye';

  @override
  String get professionRealEstate => 'Hantida ma-guurtada ah';

  @override
  String get professionResearcherScientist => 'Cilmi-baare ama saynisyahan';

  @override
  String get professionRetail => 'Tafaariiqda iyo dukaamada';

  @override
  String get professionSocialWorker => 'Shaqaale bulsho';

  @override
  String get professionStudent => 'Arday';

  @override
  String get professionTeacher => 'Macallin';

  @override
  String get professionTranslatorInterpreter => 'Turjumaan';

  @override
  String get professionLookingForWork => 'Shaqo raadinaya';

  @override
  String get professionRetired => 'Hawlgab';

  @override
  String get profileEdit => 'Wax ka beddel bogga';

  @override
  String get profileSaveChanges => 'Kaydi isbeddelada';

  @override
  String get profileCancelEdit => 'Jooji';

  @override
  String get profileLockedNotice =>
      'Jinsiga iyo taariikhda dhalashada lama beddeli karo marka boggaaga la sameeyo kadib.';

  @override
  String get profileUpdated =>
      'Alxamdulillaah, isbeddeladaada waa la kaydiyay.';

  @override
  String get emailVerifyTitle => 'Xaqiiji iimaylkaaga';

  @override
  String emailVerifyBody(String email) {
    return 'Xiriiriye xaqiijin ah ayaan u dirnay $email. Iimayl la xaqiijiyay ayaa loo baahan doonaa ka hor intaadan la kulmin xubnaha kale.';
  }

  @override
  String get emailVerifyCheck => 'Waan xaqiijiyay';

  @override
  String get emailVerifyResend => 'Dib u dir iimaylka';

  @override
  String get emailVerifySent =>
      'Iimaylka xaqiijinta waa la diray. Hubi sanduuqaaga iyo galka spam-ka.';

  @override
  String get emailVerifyNotYet =>
      'Weli lama xaqiijin. Fur xiriiriyaha ku jira iimaylka, kadibna mar kale isku day.';

  @override
  String get emailVerified => 'Iimaylka waa la xaqiijiyay';

  @override
  String get accountActionFailed =>
      'Wax baa khaldamay. Hubi xiriirka oo mar kale isku day.';

  @override
  String get accountDelete => 'Tirtir akoonka';

  @override
  String get accountDeleteTitle => 'Tirtir akoonkaaga';

  @override
  String get accountDeleteBody =>
      'Tani waxay si joogto ah u tirtiraysaa boggaaga Shukaansi, xogtaada gaarka ah iyo akoonkaaga gelitaanka. Dib looma soo celin karo.';

  @override
  String get accountDeletePassword => 'Geli furahaaga si aad u xaqiijiso';

  @override
  String get accountDeleteConfirm => 'Waan fahmay in tani tahay mid joogto ah';

  @override
  String get accountDeleteConfirmRequired => 'Fadlan xaqiiji inaad fahantay.';

  @override
  String get accountDeleteButton => 'Si joogto ah u tirtir akoonkayga';

  @override
  String get accountDeleteWrongPassword => 'Furahaasi sax ma aha.';

  @override
  String get accountDeleteFailed =>
      'Akoonkaaga lama tirtiri karin. Waxba lama tirtirin. Hubi xiriirka oo mar kale isku day.';

  @override
  String get accountDeletePartial =>
      'Boggaaga waa la tirtiray, laakiin akoonka gelitaanka lama tirtirin. Mar kale isku day si aad u dhammaystirto.';

  @override
  String get photosTitle => 'Sawiradaada';

  @override
  String get photosHint =>
      'Ku dar ilaa 6 sawir. Sawirkaaga koowaad waa sawirkaaga ugu muhiimsan. Hadda adiga oo keliya ayaa arki kara.';

  @override
  String get photosAdd => 'Ku dar sawir';

  @override
  String get photosMain => 'Ugu muhiimsan';

  @override
  String get photosMakeMain => 'Ka dhig sawirka ugu muhiimsan';

  @override
  String get photosRemove => 'Ka saar sawirka';

  @override
  String get photosView => 'Eeg sawirka';

  @override
  String get photosUploading => 'Sawirka waa la soo gelinayaa';

  @override
  String get photosUploadFailed =>
      'Sawirka lama soo gelin karin. Hubi xiriirka oo mar kale isku day.';

  @override
  String get photosUnsupported =>
      'Dooro sawir JPEG, PNG ama WebP ah. Sawirada aad u waaweyn lama isticmaali karo.';

  @override
  String get photosUpdateFailed =>
      'Sawiradaada lama cusboonaysiin karin. Mar kale isku day.';

  @override
  String get photosLoadFailed => 'Sawiradaada lama soo bandhigi karin.';

  @override
  String get photosPickFailed =>
      'Sawiradaada lama furi karin. Ka hubi ogolaanshaha sawirada habaynta taleefankaaga.';

  @override
  String photosSlot(int number) {
    return 'Sawirka $number';
  }

  @override
  String get verifyTitle => 'Xaqiiji aqoonsigaaga';

  @override
  String get verifyBody =>
      'Qaado sawir-is-qaad si kooxdayadu u xaqiijiso inaad la mid tahay sawiradaada. Bogagga la xaqiijiyay waxay kalsooni dheeraad ah ka helaan xubnaha iyo qoysaskooda.';

  @override
  String get verifyStart => 'Bilow xaqiijinta';

  @override
  String get verifyNeedsPhoto => 'Marka hore ku dar ugu yaraan hal sawir.';

  @override
  String get verifyPendingTitle => 'Xaqiijinta waa la eegayaa';

  @override
  String get verifyPendingBody =>
      'Kooxdayadu dhowaan ayay eegi doontaa sawir-is-qaadkaaga, haddii Alle idmo. Natiijadu halkan ayay ka muuqan doontaa.';

  @override
  String get verifyVerified => 'Mashaa Allah, boggaaga waa la xaqiijiyay';

  @override
  String get verifyRejectedTitle => 'Xaqiijinta lama ansixin';

  @override
  String get verifyRejectedBody =>
      'Sawir-is-qaadkaaga lama waafajin karin sawiradaada. Eeg talooyinka oo mar kale isku day.';

  @override
  String verifyReviewNote(String note) {
    return 'Faallada dib-u-eegaha: $note';
  }

  @override
  String get verifyScreenTitle => 'Xaqiiji boggaaga';

  @override
  String get verifyTipsIntro => 'Si dib-u-eegistu u dhaqso badato:';

  @override
  String get verifyTipLight =>
      'Isticmaal iftiin wanaagsan oo u jeedso kamarada.';

  @override
  String get verifyTipFace =>
      'Wejigaagu ha muuqdo si cad, adigoon xiran muraayad qorraxeed ama isticmaalin filtar.';

  @override
  String get verifyTipPrivate =>
      'Sawir-is-qaadkaagu waa gaar. Kooxda dib-u-eegista oo keliya ayaa aragta, weligiina laguma muujiyo boggaaga.';

  @override
  String get verifyTakeSelfie => 'Qaado sawir-is-qaad';

  @override
  String get verifyRetake => 'Dib u qaado';

  @override
  String get verifySubmit => 'U dir dib-u-eegis';

  @override
  String get verifySubmitting => 'Sawir-is-qaadkaaga waa la dirayaa';

  @override
  String get verifySubmitFailed =>
      'Sawir-is-qaadkaaga lama diri karin. Hubi xiriirka oo mar kale isku day.';

  @override
  String get verifyCameraFailed =>
      'Kamarada lama furi karin. Ka hubi ogolaanshaha kamarada habaynta taleefankaaga.';

  @override
  String get verifySelfiePreview => 'Sawir-is-qaadkaaga';

  @override
  String get photosResetTitle => 'Dib u bilaabi xaqiijinta?';

  @override
  String get photosResetBody =>
      'Xaqiijintaadu waxay ku xiran tahay sawirkaaga ugu muhiimsan. Beddelidda sawirkaas waxay dib u bilaabaysaa xaqiijinta, waxaadna u baahan doontaa inaad qaado sawir-is-qaad cusub si lagaa xaqiijiyo mar kale.';

  @override
  String get photosResetConfirm => 'Beddel sawirka';

  @override
  String get verifyTipNiqab =>
      'Haddii aad xiran tahay niqaab, fadlan ka qaad sawir-is-qaadkan oo keliya. Wejigaagu waa inuu muuqdaa si laguu xaqiijiyo. Sawir-is-qaadku wuu ahaanayaa mid gaar ah, waxaana arka kooxda dib-u-eegista oo keliya.';

  @override
  String get navDiscover => 'Baadh';

  @override
  String get navProfile => 'Boggayga';

  @override
  String get discoverNotListedTitle => 'Isu diyaari in lagu helo';

  @override
  String get discoverNotListedBody =>
      'Dhammaystir tallaabooyinkan si aad uga muuqato Baadhista oo aad u aragto xubnaha kale.';

  @override
  String get discoverNeedEmail => 'Xaqiiji cinwaanka iimaylkaaga';

  @override
  String get discoverNeedPhoto => 'Ku dar ugu yaraan hal sawir oo bogga ah';

  @override
  String get discoverGoToProfile => 'U gudub boggayga';

  @override
  String get discoverCheckAgain => 'Mar kale hubi';

  @override
  String get discoverEmpty =>
      'Weli bogag ku habboon lama helin. Isku day inaad ballaariso shaandhada ama dib u soo eeg dhowaan, haddii Alle idmo.';

  @override
  String get discoverLoadFailed =>
      'Bogagga lama soo bandhigi karin. Hubi xiriirka oo mar kale isku day.';

  @override
  String get discoverFilters => 'Shaandhada';

  @override
  String discoverAgeRange(int min, int max) {
    return 'Da\'da $min ilaa $max';
  }

  @override
  String get discoverAnyCountry => 'Dal kasta';

  @override
  String get discoverCountry => 'Dalka ay ku nool yihiin';

  @override
  String get discoverApply => 'Tus bogagga';

  @override
  String get discoverReset => 'Dib u deji';

  @override
  String cardNameAge(String name, int age) {
    return '$name, $age';
  }

  @override
  String cardLocation(String city, String country) {
    return '$city, $country';
  }

  @override
  String get verifiedBadge => 'Bog la xaqiijiyay';

  @override
  String photoOf(int current, int total) {
    return 'Sawirka $current ee $total';
  }

  @override
  String get photosPrivateTitle => 'Sawiradu waa gaar';

  @override
  String get photosPrivateBody =>
      'Waxay sawiradeeda la wadaagtaa xubnaha ay ansixiso.';

  @override
  String get photosRequest => 'Codso sawirada';

  @override
  String get photosRequested => 'Codsiga waa la diray';

  @override
  String get photosCancelRequest => 'Jooji codsiga';

  @override
  String get photosRequestFailed =>
      'Codsigaaga lama diri karin. Mar kale isku day.';

  @override
  String get blurTitle => 'Ku qari sawiradayda Baadhista';

  @override
  String get blurBody =>
      'Xubnuhu waxay arkayaan nooc la qariyay ilaa aad ansixiso codsigooda.';

  @override
  String get blurFailed =>
      'Asturnaanta sawiradaada lama beddeli karin. Mar kale isku day.';

  @override
  String get requestsTitle => 'Codsiyada sawirada';

  @override
  String get requestsEmpty => 'Hadda codsi ma jiro.';

  @override
  String get requestsApprove => 'Ansixi';

  @override
  String get requestsDecline => 'Diid';

  @override
  String get viewersTitle => 'Way arki karaan sawiradaada';

  @override
  String get viewersRemove => 'Ka saar';

  @override
  String get requestsLoadFailed => 'Codsiyada lama soo bandhigi karin.';

  @override
  String get filterPractice => 'Dhaqanka diinta';

  @override
  String get reportAction => 'Ka warbixi';

  @override
  String get blockAction => 'Xannib';

  @override
  String cardMoreActions(String name) {
    return 'Doorashooyin kale oo ku saabsan $name';
  }

  @override
  String reportTitle(String name) {
    return 'Ka warbixi $name';
  }

  @override
  String reportBody(String name) {
    return 'Noo sheeg waxa khaldan. Warbixinnadu waa qarsoodi: $name ma ogaan doono cidda ka warbixisay.';
  }

  @override
  String get reportReasonFakeProfile =>
      'Bog been abuur ah ama qof kale iska dhigid';

  @override
  String get reportReasonInappropriatePhotos => 'Sawiro aan habboonayn';

  @override
  String get reportReasonHarassment => 'Dhibaateyn ama ixtiraam darro';

  @override
  String get reportReasonScam => 'Khiyaano ama lacag weydiisasho';

  @override
  String get reportReasonUnderage =>
      'Waxaa laga yaabaa in qofkani ka yar yahay 18 sano';

  @override
  String get reportReasonNotSerious => 'Kama dhab aha guurka';

  @override
  String get reportReasonOther => 'Wax kale';

  @override
  String get reportNote => 'Faahfaahin (ikhtiyaari)';

  @override
  String reportAlsoBlock(String name) {
    return 'Sidoo kale xannib $name';
  }

  @override
  String get reportSubmit => 'Dir warbixinta';

  @override
  String get reportSent =>
      'Jazaakallaahu khayran. Kooxdayadu way eegi doontaa warbixintaada.';

  @override
  String get reportFailed =>
      'Warbixintaada lama diri karin. Mar kale isku day.';

  @override
  String blockTitle(String name) {
    return 'Ma xannibaysaa $name?';
  }

  @override
  String get blockBody =>
      'Mar dambe isma arki doontaan Baadhista, ogolaanshaha sawiradana way dhammaanayaan. Looma sheegayo.';

  @override
  String get blockFailed => 'Lama xannibi karin. Mar kale isku day.';

  @override
  String get blockedTitle => 'Xubnaha la xannibay';

  @override
  String get unblockAction => 'Ka qaad xannibaadda';

  @override
  String get suspendedTitle => 'Akoonkaaga waa la hakiyay';

  @override
  String get suspendedBody =>
      'Ma isticmaali kartid Shukaansi inta akoonkaagu hakisan yahay.';

  @override
  String suspendedReason(String reason) {
    return 'Sababta: $reason';
  }

  @override
  String suspendedContact(String email) {
    return 'Si aad uga dacwoodo, la xiriir $email.';
  }

  @override
  String stepsDone(int done, int total) {
    return '$done ee $total waa dhammaystiran';
  }

  @override
  String photosCount(int count, int max) {
    return '$count ee $max waa la daray';
  }

  @override
  String get verifyStatusNotStarted => 'Lama bilaabin';

  @override
  String get verifyStatusPending => 'Waa la eegayaa';

  @override
  String get verifyStatusRejected => 'Lama ansixin';

  @override
  String get navLikes => 'Xiisaha';

  @override
  String get navMatches => 'Isku-aadka';

  @override
  String get navChats => 'Fariimaha';

  @override
  String get matchesSoonBody =>
      'Marka laba xubnood midba midka kale xiiso u muujiyo, waa isku-aad. Isku-aadyadaadu halkan ayay ka muuqan doonaan.';

  @override
  String get browseDiscover => 'U gudub Baadh';

  @override
  String get settingsLanguage => 'Luqadda';

  @override
  String get termsOfUse => 'Shuruudaha Isticmaalka';

  @override
  String get privacyPolicy => 'Siyaasadda Asturnaanta';

  @override
  String get legalTitle => 'Intaadan sii wadin';

  @override
  String get legalBody =>
      'Fadlan akhri Shuruudaha Isticmaalka iyo Siyaasadda Asturnaanta. Waxay raacayaan anshaxa Islaamka, waxayna sharxayaan sida aan u ilaalinno xogtaada.';

  @override
  String get legalTermsPoint =>
      'Guur raadin daacadnimo, xishood iyo ixtiraam leh.';

  @override
  String get legalPrivacyPoint =>
      'Xogtaada weligeed lama iibiyo, lamana wadaago xayeysiiyeyaal.';

  @override
  String get legalAgree =>
      'Waan akhriyay oo waan aqbalay Shuruudaha Isticmaalka iyo Siyaasadda Asturnaanta.';

  @override
  String get legalContinue => 'Aqbal oo sii wad';

  @override
  String get legalSaveFailed =>
      'Oggolaanshahaaga lama kaydin karin. Hubi internetkaaga oo mar kale isku day.';

  @override
  String get legalCheckFailed =>
      'Akoonkaaga lama hubin karin. Hubi internetkaaga oo mar kale isku day.';

  @override
  String get legalLoadFailed => 'Dukumentigan lama furi karin.';

  @override
  String get verifyStepPhoto => 'Sawir';

  @override
  String get verifyStepSelfie => 'Sawir-is-qaad';

  @override
  String get verifyStepReview => 'Dib-u-eegis';

  @override
  String get stepStateDone => 'la dhammeeyay';

  @override
  String get stepStateCurrent => 'socda';

  @override
  String get stepStateUpcoming => 'xiga';

  @override
  String get verifyHeadline => 'Xaqiiji inaad adigu tahay';

  @override
  String get verifyIntro =>
      'Qaado sawir-is-qaad degdeg ah si kooxdayadu ugu barbardhigto sawirkaaga ugu muhiimsan.';

  @override
  String get verifyPrivateTitle => 'Gaar ah oo ammaan ah';

  @override
  String get verifyCareTitle => 'Si taxaddar leh ayaa loo eegaa';

  @override
  String get verifyCareBody =>
      'Waxaan u isticmaalnaa oo keliya inaan xaqiijinno inaad adigu tahay.';

  @override
  String get verifyCheckHeadline => 'Hubi sawir-is-qaadkaaga';

  @override
  String get verifyCheckBody =>
      'Hubi in wejigaagu cad yahay oo iftiin leeyahay, kadibna u dir dib-u-eegis.';

  @override
  String get verifySubmittedChip => 'Sawir-is-qaadka waa la diray';

  @override
  String get verifySubmittedTitle => 'Xaqiijintaada waa la eegayaa';

  @override
  String get verifySubmittedBody =>
      'Jazaakallaahu khayran. Kooxdayadu waxay isbarbardhigi doontaa sawir-is-qaadkaaga iyo sawirkaaga ugu muhiimsan, natiijadana halkan ayaad ka arki doontaa, haddii Alle idmo.';

  @override
  String get reviewStepProfile => 'Bogga waa la dhammaystiray';

  @override
  String get reviewStepProfileBody =>
      'Xogtaada iyo sawiradaada waa la kaydiyay.';

  @override
  String get reviewStepReview => 'Dib-u-eegista xaqiijinta';

  @override
  String get reviewStepReviewBody =>
      'Kooxdayadu gacan ayay ku eegaan sawir-is-qaad kasta.';

  @override
  String get reviewStepBadge => 'Calaamadda xaqiijinta';

  @override
  String get reviewStepBadgeBody =>
      'Marka la ansixiyo, boggaagu wuxuu yeelan doonaa calaamadda buluugga ah ee xaqiijinta, haddii Alle idmo.';

  @override
  String get verifyContinue => 'Ku sii wad Shukaansi';

  @override
  String get likeAction => 'Muuji xiiso';

  @override
  String get withdrawInterest => 'Ka noqo xiisaha';

  @override
  String get matchedLabel => 'Isku-aad';

  @override
  String likeSent(String name) {
    return 'Alxamdulillaah, xiisahaaga waa loo diray $name.';
  }

  @override
  String get interestFailed =>
      'Taasi ma shaqayn. Hubi internetkaaga oo mar kale isku day.';

  @override
  String get matchTitle => 'Mashaa Allah, waa isku-aad!';

  @override
  String matchBody(String name) {
    return 'Adiga iyo $name labadiinaba xiiso ayaad muujiseen. Alle khayr ha ku dhex rido.';
  }

  @override
  String get matchPhotosNote =>
      'Hadda midba midka kale sawiradiisa wuu arki karaa.';

  @override
  String get matchMessagingSoon =>
      'Fariimuhu dhowaan ayay furmayaan, haddii Alle idmo.';

  @override
  String get viewMatches => 'Eeg isku-aadyada';

  @override
  String get keepBrowsing => 'Sii baadh';

  @override
  String get likesReceivedTab => 'Ku xiiseeyay';

  @override
  String get likesSentTab => 'Aad xiisaysay';

  @override
  String get likesReceivedEmpty =>
      'Weli cidna xiiso kuma muujin. Boggaaga dhammaystir oo dhowaan dib u soo eeg, haddii Alle idmo.';

  @override
  String get likesSentEmpty =>
      'Weli cidna xiiso uma muujin. Riix wadnaha bog kasta oo Baadh ku jira.';

  @override
  String get likeBack => 'Xiiso u celi';

  @override
  String get declineInterest => 'Igama habboona';

  @override
  String get likesLoadFailed => 'Xiisaha lama soo shubi karin.';

  @override
  String get matchesEmptyTitle => 'Weli isku-aad ma jiro';

  @override
  String get matchesLoadFailed => 'Isku-aadyada lama soo shubi karin.';

  @override
  String get unmatch => 'Ka saar isku-aadka';

  @override
  String unmatchTitle(String name) {
    return 'Ka saar isku-aadka $name?';
  }

  @override
  String get unmatchBody =>
      'Mar dambe isku-aad ma ahaan doontaan, sawir wadaagista dhexdiinnana way dhammaanaysaa. Si aad mar kale isugu aaddaan, labadiinuba waa inaad mar kale xiiso muujisaan.';

  @override
  String get viewProfile => 'Eeg bogga';

  @override
  String likesNewCount(int count) {
    return '$count cusub';
  }

  @override
  String get discoverForYou => 'Kuu habboon';

  @override
  String get discoverNewMembers => 'Xubno cusub';

  @override
  String get forYouSubtitle =>
      'Xubnaha ku habboon doorashooyinka lammaanahaaga.';

  @override
  String get newMembersSubtitle =>
      'Xubnaha ugu cusub, kuwa ugu dambeeyay marka hore.';

  @override
  String get forYouSetupTitle => 'Noo sheeg cidda aad raadinayso';

  @override
  String get forYouSetupBody =>
      'Deji doorashooyinka lammaanahaaga, waxaanan ku tusi doonnaa xubnaha ku habboon, haddii Alle idmo.';

  @override
  String get setPreferences => 'Deji doorashooyinka';

  @override
  String get partnerPreferences => 'Doorashooyinka lammaanaha';

  @override
  String get prefCountries => 'Dalalka ay ku nool yihiin';

  @override
  String get prefCountriesHint => 'Ka tag madhan dal kasta. Dooro ilaa 10.';

  @override
  String get prefAddCountry => 'Ku dar dal';

  @override
  String prefRemoveCountry(String country) {
    return 'Ka saar $country';
  }

  @override
  String get prefSave => 'Kaydi doorashooyinka';

  @override
  String get prefSaved => 'Alxamdulillaah, doorashooyinkaaga waa la kaydiyay.';

  @override
  String get prefSaveFailed =>
      'Doorashooyinkaaga lama kaydin karin. Mar kale isku day.';

  @override
  String get prefNotSet => 'Weli lama dejin';

  @override
  String prefAges(int min, int max) {
    return 'Da\'da $min–$max';
  }

  @override
  String prefCountryCount(int count) {
    return '$count dal';
  }

  @override
  String get prefAnyAnswer => 'Mid kasta';

  @override
  String get roleTitle => 'Sidee baad u isticmaali doontaa Shukaansi?';

  @override
  String get roleMember => 'Waxaan raadinayaa lammaane';

  @override
  String get roleMemberBody =>
      'Samee boggaaga oo la kulan Muslimiin guur raadinaya.';

  @override
  String get roleWali => 'Waxaan ahay Wali';

  @override
  String get roleWaliBody =>
      'Qof qoyskaaga ka mid ah ayaa kuu casuumay inaad ansixiso isku-aadyadiisa.';

  @override
  String get waliSetupTitle => 'Ku soo biir Wali ahaan';

  @override
  String get waliSetupBody =>
      'Geli magacaaga iyo koodhka uu qofka qoyskaagu kula wadaagay.';

  @override
  String get waliYourName => 'Magacaaga';

  @override
  String get waliCode => 'Koodhka casuumaadda';

  @override
  String get waliJoin => 'Ku biir';

  @override
  String get waliCodeInvalid =>
      'Koodhkan ma shaqaynayo ama wuu dhacay. Weydiiso mid cusub.';

  @override
  String get waliHomeTitle => 'Wali';

  @override
  String waliGreeting(String name) {
    return 'Assalaamu calaykum, $name';
  }

  @override
  String waliGuarding(String names) {
    return 'Waxaad Wali u tahay $names.';
  }

  @override
  String get waliNoMembers =>
      'Weli qofna Wali uma tihid. Qofka qoyskaaga weydiiso koodh casuumaad.';

  @override
  String get waliAddMember => 'Geli koodh kale';

  @override
  String get waliRequestsTitle => 'Codsiyada isku-aadka';

  @override
  String get waliNoRequests =>
      'Weli codsi isku-aad ma jiro. Halkan ayaa lagu weydiin doonaa marka isku-aad cusub yimaado, haddii Alle idmo.';

  @override
  String waliRequestFor(String name) {
    return 'Isku-aad loogu talagalay $name';
  }

  @override
  String get waliApprove => 'Ansixi';

  @override
  String get waliDecline => 'Diid';

  @override
  String get waliApproved =>
      'Mashaa Allah, waad ansixisay isku-aadkan. Alle barako ha ka dhigo.';

  @override
  String get waliDeclined => 'Waad diiday isku-aadkan.';

  @override
  String get waliDeclineTitle => 'Ma diidaysaa isku-aadkan?';

  @override
  String get waliDeclineBody =>
      'Labada xubnoodba waxay arki doonaan in isku-aadka la diiday, mana awoodi doonaan inay is-fariimiyaan.';

  @override
  String get waliStatusApproved => 'La ansixiyay';

  @override
  String get waliStatusDeclined => 'La diiday';

  @override
  String get waliStatusWaiting => 'Adiga ayaa la sugayaa';

  @override
  String waliStop(String name) {
    return 'Jooji inaad Wali u ahaato $name';
  }

  @override
  String waliStopTitle(String name) {
    return 'Ma joojinaysaa inaad Wali u ahaato $name?';
  }

  @override
  String waliStopBody(String name) {
    return '$name waa inay Wali cusub casuunto.';
  }

  @override
  String get waliPhotosNote =>
      'Sawirada waxaa la wadaagaa oo keliya labada xubnood.';

  @override
  String get waliLoadFailed => 'Tan lama soo shubi karin.';

  @override
  String get waliCardTitle => 'Waligaaga';

  @override
  String get waliRequiredBody =>
      'Waa khasab walaalaha: isku-aadyadaadu waxay is-fariimin karaan oo keliya marka Waligaagu ansixiyo.';

  @override
  String get waliOptionalBody =>
      'Ikhtiyaari: ku dar Wali si uu u ansixiyo isku-aadyadaada ka hor fariimaha.';

  @override
  String get waliRequiredChip => 'Khasab';

  @override
  String get waliInvite => 'Casuun Waligaaga';

  @override
  String get waliInviteCode => 'Koodhka casuumaadda';

  @override
  String waliInviteExpires(String date) {
    return 'Wuu shaqaynayaa ilaa $date';
  }

  @override
  String get waliShareCode => 'Wadaag koodhka';

  @override
  String get waliCopyCode => 'Koobiyee koodhka';

  @override
  String get waliCopied => 'Koodhka waa la koobiyeeyay';

  @override
  String get waliNewCode => 'Koodh cusub';

  @override
  String waliShareMessage(String code) {
    return 'Assalaamu calaykum. Fadlan noqo Waligayga Shukaansi. Soo deji app-ka, dooro \"Waxaan ahay Wali\" oo geli koodhkan: $code. Wuxuu shaqaynayaa 7 maalmood.';
  }

  @override
  String waliLinked(String name) {
    return '$name waa Waligaaga';
  }

  @override
  String get waliLinkedBody =>
      'Waligaagu wuxuu ansixiyaa isku-aadyadaada ka hor intaadan is-fariimin.';

  @override
  String get waliRemove => 'Ka saar Wali';

  @override
  String waliRemoveTitle(String name) {
    return 'Ma ka saaraysaa $name inuu Waligaaga ahaado?';
  }

  @override
  String get waliRemoveBody =>
      'Ansixintoodii waa la tirtirayaa, Wali cusubna waa inuu mar kale ansixiyo isku-aadyadaada.';

  @override
  String get approvalNeedsWali => 'Ku dar Waligaaga si aad u sii wadato';

  @override
  String get approvalWaitingYours => 'Waxaa la sugayaa ansixinta Waligaaga';

  @override
  String get approvalWaitingTheirs => 'Waxaa la sugayaa ansixinta Waligooda';

  @override
  String get approvalDeclined => 'Wali ayaa diiday isku-aadkan';

  @override
  String get chatsActive => 'Wada-sheekaysiyada';

  @override
  String get chatsNewMatches => 'Isku-aadyo cusub';

  @override
  String get chatsNewMatchesBody => 'Salaan oo bilow wada-hadal ixtiraam leh.';

  @override
  String get chatsEmptyTitle => 'Weli wada-sheekaysi ma jiro';

  @override
  String get chatsEmptyBody =>
      'Marka aad labadiinuba xiiso muujisaan, isku-aadkaagu halkan ayuu ka muuqan doonaa, haddii Alle idmo.';

  @override
  String get viewMatchesAction => 'Eeg isku-aadyada';

  @override
  String get chatsLoadFailed => 'Wada-sheekaysiyada lama soo shubi karin.';

  @override
  String get messageAction => 'Farriin';

  @override
  String get messageHint => 'Qor farriin';

  @override
  String get messageSend => 'Dir';

  @override
  String get messageSendFailed =>
      'Farriintaada lama diri karin. Mar kale isku day.';

  @override
  String get chatStarterTitle => 'Ku bilow salaan';

  @override
  String get chatStarterBody =>
      'Wada-hadalka ka dhig mid ixtiraam leh oo diiradda saaraya guurka. Ku dar qoysaskiinna marka waqtigu ku habboon yahay.';

  @override
  String get chatStarterSalaam => 'Assalaamu calaykum';

  @override
  String get chatLocked =>
      'Fariimuhu waxay furmayaan marka ansixinta Waliga loo baahan yahay la helo.';

  @override
  String get chatYesterday => 'Shalay';

  @override
  String get chatUnread => 'Farriin cusub';

  @override
  String chatYou(String text) {
    return 'Adiga: $text';
  }

  @override
  String chatsUnreadCount(int count) {
    return '$count aan la akhrin';
  }

  @override
  String get messageFromYou => 'Waxaad tiri';

  @override
  String messageFrom(String name) {
    return '$name ayaa yiri';
  }

  @override
  String get activityTitle => 'Ogeysiisyo';

  @override
  String get activityEmpty =>
      'Wax cusub ma jiraan. Xiisaha, isku-aadyada iyo fariimaha cusub halkan ayay ka soo muuqan doonaan, haddii Alle idmo.';

  @override
  String get activityOpenOnly =>
      'Digniinuhu waxay muuqdaan marka Shukaansi furan yahay. Ogeysiisyada taleefanka marka app-ku xiran yahay dhowaan ayay imanayaan.';

  @override
  String activityLiked(String name) {
    return '$name ayaa xiiso kuu muujiyay';
  }

  @override
  String activityMatched(String name) {
    return 'Mashaa Allah, adiga iyo $name waad isku aaddeen';
  }

  @override
  String activityYourWaliApproved(String name) {
    return 'Waligaagu wuxuu ansixiyay isku-aadkaaga $name';
  }

  @override
  String activityYourWaliDeclined(String name) {
    return 'Waligaagu wuxuu diiday isku-aadkaaga $name';
  }

  @override
  String activityTheirWaliApproved(String name) {
    return 'Waliga $name wuxuu ansixiyay isku-aadkiinna. Hadda waad is-fariimin kartaan, haddii Alle idmo.';
  }

  @override
  String activityTheirWaliDeclined(String name) {
    return 'Waliga $name wuxuu diiday isku-aadka';
  }

  @override
  String activityMessage(String name) {
    return 'Farriin cusub oo ka timid $name';
  }

  @override
  String get activityView => 'Eeg';

  @override
  String get activityNew => 'Cusub';

  @override
  String get mutualTitle => 'Mashaa Allah, labadiinuba waad is xiiseysaan';

  @override
  String get mutualBody =>
      'Isku-aadku wuxuu u baahan yahay Premium mid idinka mid ah. Marka midkiin kor u qaado, isku-aadka waa la samaynayaa, haddii Alle idmo.';

  @override
  String get mutualNeedsPremium =>
      'Waad is xiiseysaan: Premium ayaa loo baahan yahay si aad isugu aaddaan';

  @override
  String get viewPlans => 'Eeg qorshayaasha';

  @override
  String get plansTitle => 'Dooro qorshahaaga';

  @override
  String get planFree => 'Bilaash';

  @override
  String get planPremium => 'Premium';

  @override
  String get planVip => 'VIP';

  @override
  String get planHeadlineFree => 'Bilow raadintaada';

  @override
  String get planHeadlinePremium => 'La kulan doorashooyin badan';

  @override
  String get planHeadlineVip => 'Marka hore la arag';

  @override
  String get planSubFree => 'Wax kasta oo aad ku bilaabayso, lacag la\'aan.';

  @override
  String get planSubPremium =>
      'La isku aad qof kasta oo aad is xiiseysaan, oo la fariimi isku-aadyadaada.';

  @override
  String get planSubVip =>
      'Wax kasta oo Premium ku jira, oo leh mudnaan Baadh.';

  @override
  String get featureProfile => 'Samee boggaaga oo la xaqiiji';

  @override
  String get featureBrowse => 'Baadh oo xiiso muuji';

  @override
  String get featureMatchPremium => 'La isku aad xubnaha Premium leh';

  @override
  String get featureMatchAnyone => 'La isku aad qof kasta oo aad is xiiseysaan';

  @override
  String get featureMessage =>
      'La fariimi isku-aadyadaada, marka Wali ansixiyo';

  @override
  String get featurePriority => 'Marka hore lagu muujiyo Baadh';

  @override
  String get featureEverythingPremium => 'Wax kasta oo Premium ku jira';

  @override
  String get perMonth => '/ bishii';

  @override
  String get planCancelAnytime => 'Waqti kasta waad joojin kartaa.';

  @override
  String planContinue(String plan) {
    return 'Ku sii wad $plan';
  }

  @override
  String get planCurrent => 'Qorshahaaga hadda';

  @override
  String get planComingSoonTitle => 'Dhowaan, haddii Alle idmo';

  @override
  String get planComingSoonBody =>
      'Is-diiwaangelinta Google Play way soo socotaa. Inta ka horreysa, kooxdayadu waxay akoonkaaga ku dari karaan Premium ama VIP.';

  @override
  String get planRenewNote =>
      'Marka la heli karo, is-diiwaangelintu si toos ah ayay u cusboonaysiisaa ilaa la joojiyo.';

  @override
  String get compareAllPlans => 'Isbarbardhig dhammaan qorshayaasha';

  @override
  String get membershipTitle => 'Xubinnimadayda';

  @override
  String get membershipFreeBody => 'Ku baadh Shukaansi astaamaha aasaasiga ah.';

  @override
  String membershipActive(String plan, String date) {
    return '$plan ilaa $date';
  }

  @override
  String get previewBadge => 'Tijaabo · bogag aan dhab ahayn';

  @override
  String get previewScenarios => 'Xaaladaha tijaabada';

  @override
  String get previewScenariosBody =>
      'Wax kasta oo halkan ah waa tijaabo qalabkan ku jirta. Waxba looma diro Shukaansi.';

  @override
  String get scenarioPopulated => 'Xubno la baadho';

  @override
  String get scenarioPrefsNotSet => 'Doorashooyin aan la dejin';

  @override
  String get scenarioNoMatches => 'Bogag ku habboon ma jiraan';

  @override
  String get scenarioLoading => 'Soo shubid';

  @override
  String get scenarioNetworkError => 'Khalad shabakad';

  @override
  String get scenarioIncomplete => 'Bog aan dhammaystirnayn';

  @override
  String get scenarioAwaitingReview => 'Xaqiijin la eegayo';

  @override
  String get scenarioEmptyActivity => 'Xiiso iyo wada-sheekaysi midna ma jiro';

  @override
  String get previewSimulatePremium => 'Tijaabi Premium akoonkan';

  @override
  String get previewNotAvailable => 'Ficilkan laguma heli karo tijaabada.';

  @override
  String get previewDisabledTitle => 'Tijaabadu way xiran tahay';

  @override
  String get previewDisabledBody =>
      'Ku shid nooc debug ama profile ah adigoo isticmaalaya --dart-define=SHUKAANSI_PREVIEW=true.';

  @override
  String get photoVerified => 'Sawirka waa la xaqiijiyay';

  @override
  String get photoVerifiedInfo =>
      'Kooxdayadu waxay isbarbardhigeen sawir-is-qaad gaar ah iyo sawirada xubintan. Ma xaqiijiso dukumentiyada aqoonsiga.';

  @override
  String aboutName(String name) {
    return 'Ku saabsan $name';
  }

  @override
  String marriagePlans(String timeline) {
    return 'Qorshaha guurka: $timeline';
  }

  @override
  String get sectionBackground => 'Asalka';

  @override
  String get factLivesIn => 'Ku nool';

  @override
  String get factPractice => 'Dhaqanka diineed';

  @override
  String get factRelocation => 'U furan guuritaan';

  @override
  String get conceptLabel => 'Fikrad';

  @override
  String get interestsTitle => 'Hiwaayadaha';

  @override
  String get photoLoadFailed => 'Sawirkan lama soo shubi karin.';

  @override
  String get closePhoto => 'Xir sawirka';

  @override
  String openPhoto(int current, int total) {
    return 'Fur sawirka $current ee $total';
  }

  @override
  String get passAction => 'Ka gudub';

  @override
  String passedName(String name) {
    return 'Waad ka gudubtay $name';
  }

  @override
  String get undoAction => 'Ka noqo';

  @override
  String get seenEveryoneTitle => 'Hadda qof walba waad aragtay';

  @override
  String get seenEveryoneBody =>
      'Xubno cusub ayaa si joogto ah ku soo biira. Mar dambe dib u eeg, haddii Alle idmo.';

  @override
  String get noMatchesTitle => 'Xubno ku habboon doorashooyinkaaga ma jiraan';

  @override
  String get noMatchesBody => 'Isku day da\' ballaaran ama dalal badan.';

  @override
  String get adjustPreferences => 'Wax ka beddel doorashooyinka';

  @override
  String get networkErrorTitle => 'Lama xiriiri karin';

  @override
  String get networkErrorBody => 'Hubi internetkaaga oo mar kale isku day.';

  @override
  String get newMembersEmpty =>
      'Weli xubno cusub ma jiraan. Dhowaan dib u eeg, haddii Alle idmo.';

  @override
  String get likeStatusLikesYou => 'Ku xiiseeyay';

  @override
  String get likeStatusWaiting => 'Jawaab ayaa la sugayaa';

  @override
  String get likeStatusMutual => 'Waad is xiiseysaan';

  @override
  String get profileProgressTitle => 'Horumarkaaga';

  @override
  String get progressAccount => 'Akoon';

  @override
  String get progressAccountTodo => 'Xaqiiji iimaylkaaga';

  @override
  String get progressProfile => 'Bog';

  @override
  String get progressVisible => 'Wuxuu ka muuqdaa Baadh';

  @override
  String get progressAddPhoto => 'Ku dar sawir si aad uga muuqato Baadh';

  @override
  String get progressVerification => 'Xaqiijinta sawirka';

  @override
  String get verifyStatusVerified => 'La xaqiijiyay';

  @override
  String get previewProfile => 'Eeg bogaaga';

  @override
  String get managePhotos => 'Maamul sawirada';

  @override
  String get settingsTitle => 'Dejinta';

  @override
  String get yourPlans => 'Qorshayaasha iyo doorashooyinka';

  @override
  String get profilePrivateDetails =>
      'Dhammaan jawaabahaaga, oo ay ku jiraan xogta gaarka ah';

  @override
  String get chatsStartHint =>
      'Taabo isku-aad cusub si aad u aragto boggooda oo aad salaan ugu dirto.';

  @override
  String get loadingSlow => 'Wuu ka daahayaa sidii caadiga ahayd?';

  @override
  String profileComplete(int percent) {
    return '$percent% dhammaystiran';
  }

  @override
  String get verifyNudgeTitle =>
      'Xaqiiji sawirkaaga si aad u hesho kalsooni dheeraad ah';

  @override
  String get verifyNudgeBody =>
      'Xubnaha iyo qoysaskuba aad bay ugu kalsoon yihiin bogagga la xaqiijiyay. Waxay u baahan tahay sawir-is-qaad degdeg ah oo keliya.';

  @override
  String get appLockTitle => 'Ku fur faraha, wejiga ama PIN-ka';

  @override
  String get appLockSubtitle =>
      'Waxay ku weydiinaysaa marka Shukaansi la furo, ama 5 daqiiqo ka dib';

  @override
  String get appLockReason => 'Fur Shukaansi';

  @override
  String get appLockEnableReason =>
      'Xaqiiji inaad adigu tahay si aad u shiddo qufulka app-ka';

  @override
  String get appLockOn => 'Mashaa Allah, qufulka app-ka waa shidan yahay';

  @override
  String get appLockUnavailable =>
      'Marka hore taleefankaaga ku samee faraha, wejiga ama qufulka shaashadda.';

  @override
  String get lockedTitle => 'Shukaansi waa xiran yahay';

  @override
  String get lockedBody =>
      'Isticmaal faraha, wejiga ama PIN-ka taleefankaaga si aad u sii wadato.';

  @override
  String get unlockAction => 'Fur';

  @override
  String get unlockFailed => 'Lama furin. Isku day mar kale.';
}
