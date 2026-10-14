# Shukaansi

Shukaansi is a marriage-focused Muslim matrimonial app, initially serving Somali
Muslims and the diaspora (Android/iOS, Flutter + Firebase), with a Flutter web
admin dashboard.

## Brand (0.10.0)

Logo, symbol, launcher icons and splash artwork live in assets/branding/
(shukaansi_logo_transparent.png, shukaansi_symbol_transparent.png,
app_icon_1024.png, app_icon_foreground_1024.png, splash_1284x2778.png). Tagline:
"Halal • Serious • Together" (Somali: "Xalaal • Dhab ah • Wadajir"). Colours:
Deep Teal #054744 (primary), Gold #E0AA4F (dark #C9923A, light #F4C66D), Ivory
#FEFEFC behind the logo; app pages use white cards on a warm-neutral page
(lib/theme/app_theme.dart). The previous logo and tagline have been removed.
Dart package: shukaansi; root widget: ShukaansiApp. Android/iOS/web display names
are Shukaansi. Firebase project kumee-development and mobile ID com.kumee.app are
retained technical identities, preserving existing accounts and app updates.
Repository/vault folder names remain legacy paths so persistent recovery links work.

Regenerate native assets with dart run flutter_launcher_icons and
 dart run flutter_native_splash:create after changing the brand artwork.
Latest development APK: see "Installing the current development APK" below.

## Admin dashboard and safety (0.7.0+11)

**Dashboard:** https://kumee-development.web.app (Flutter web, entry point
`lib/admin/admin_main.dart`, English only). Build and publish:

```sh
flutter build web -t lib/admin/admin_main.dart --release
firebase deploy --only hosting --project kumee-development
```

**Adding staff (Firebase console, Firestore):** the person signs up in the app (or
has any Firebase Auth email account). Copy their user UID from Authentication, then
create a document in collection `admins` with that UID as the document ID:

- `role`: `admin` (everything, including private date of birth and phone),
  `reviewer` (verifications only) or `moderator` (members, suspensions, reports).
- `reviewGender` (optional, reviewers only): `female` or `male`, so women's
  selfies are reviewed by women. Leave it out to review everyone.

Clients can never write `admins`; only the console can.

**Sections by role:** Overview counts (all); Verifications (admin/reviewer: selfie
next to profile photos, Approve, Reject with a reason shown to the member;
rejection removes the listing); Members (admin/moderator: search by name prefix or
member id, profile, photos, status, Suspend with a reason, Reactivate, Remove from
Discover); Reports (admin/moderator: Resolve, Dismiss, or Suspend the reported
member); Memberships (admin: placeholder until payments).

**In the app:** a ⋮ menu on each Discover card offers **Report** (reason, optional
note, optional block) and **Block** (confirmation; photo permissions between the two
end). Blocked members never see each other (rules check `blocks/{blocker_blocked}`
both ways); My profile lists blocked members with Unblock. Suspended members see a
locked screen with the reason (and `supportEmail` from `lib/models/moderation.dart`
once set) and cannot be listed or browse.

## Discover (0.6.0+10)

Complete profiles open on a two-tab home: **Discover** and **My profile**.

- **Listing**: `publicProfiles/{uid}` is rebuilt by the owner's app on each
  Discover visit (`FirestoreDiscoveryService.syncListing`). Security rules check
  every field against the owner's records at write time: unchanged profile
  answers, `birthYearMonth` derived from the private birth date (age shown, never
  the date), the current photo order, `photosBlurred` from her setting, `verified`
  equal to the reviewer's decision, and a verified email. A listing needs at least
  one photo. Profile edits and any photo or blur change delete the listing in the
  same write (rules enforce this); it is re-created on the next Discover visit.
- **Who sees whom**: only listed members, only the opposite gender, never
  themselves. Queries must filter `gender` (indexes in `firestore.indexes.json`).
  Country is filtered by the query; age, marital status and practice on the device.
- **Blue check**: `verified` listings show a blue check (`VerifiedBadge`).
- **Photo blur (women)**: "Blur my photos in Discover" stores `blurred` in
  `profilePhotos/{uid}`. Every upload also stores a 24 px blurred copy in
  `profilePhotoBlurFiles/{uid}/items/{id}`. Viewers get originals only if she does
  not blur or has approved them (`photoAccess/{owner}/items/{viewer}`); otherwise
  only the blurred copy, enlarged and blurred on screen. Viewers request access
  (`photoRequests/{owner}/items/{viewer}`); she approves, declines or later
  removes access from My profile. Matches will also grant access in the next stage.
- **Reviewer note**: after approving a verification in the console, the blue check
  appears when the member next opens Discover. If you revoke a previous approval,
  also delete their `publicProfiles/{uid}` document.
- Not yet: likes/matching, blocking/reporting, pagination tuning for large numbers
  of members, Storage-backed equivalents of the new rules.

## Photos and profile verification (0.5.2+9)

**Verification policy (user decisions, 2026-10-01):** the selfie must show the
whole face; women who wear the niqab remove it for this private selfie only (a
dedicated tip appears on women's profiles). Verification is tied to the main
photo: making another photo main or removing the main photo deletes the
verification record in the same transaction, after a confirmation when a request
is pending or approved. The rules reject a main-photo change while a
verification record still exists.


**Free-plan storage (current):** image bytes are stored in Firestore through
`FirestorePhotoFiles` because Firebase Storage needs the Blaze plan. Each image is
one owner-only document, `profilePhotoFiles/{uid}/items/{id}` or (write-only)
`verificationSelfieFiles/{uid}/items/{id}`, holding `contentType` and `data`
(bytes, at most 900 KB; the picker resizes to 1080 px at 80% quality). Firestore
rules deployed 2026-10-01; `storage.rules` is ready but not deployed. To move to
Storage after the Blaze upgrade, create the bucket, deploy
`firebase deploy --only storage`, swap `FirestorePhotoFiles` for
`StoragePhotoFiles` in `lib/main.dart`, and migrate existing images.

Reviewing a selfie: in the Firebase console open
`verificationSelfieFiles/{uid}/items/{selfieId}`, copy the `data` value into
`tool/review/view-image.html` (offline, opens in any browser) to see it, compare it
with the user's photos the same way, then edit `verifications/{uid}` as below.


- **Photos**: up to 6 owner-only photos (first is the main photo) with add, make
  main, remove and full-screen view. `image_picker` resizes to 1600 px at 85%
  quality on the device; files are checked by signature (JPEG/PNG/WebP, < 5 MB).
  Files live at `profilePhotos/{uid}/{id}` in Storage; order lives in Firestore
  `profilePhotos/{uid}`. Images are read with authenticated `getData`, never
  public download URLs.
- **Verification**: a front-camera selfie at `verificationSelfies/{uid}/{id}`
  (no client can read it, not even the owner) and `verifications/{uid}` with
  status `pending`. Owners may only submit (or resubmit after rejection) a
  pending request; at least one photo is required.
- **Admin review (interim, until the dashboard)**: in the Firebase console, open
  the selfie in Storage and compare it with the photos, then edit
  `verifications/{uid}`: set `status` to `verified` or `rejected`, optionally add
  `reviewNote` (shown to the user) and `reviewedAt`. Console edits bypass client
  rules; ordinary users can never mark themselves verified.
- **Account deletion** removes photos, selfies and both media records first.
- **Motion**: shared tokens in `lib/theme/motion.dart` (strong ease-out, <= 220 ms,
  0.97 press scale, enter from 0.95, zero under reduced motion) used by
  `Pressable`/`EnterTransition`.

The original Storage design (paths `profilePhotos/{uid}/{id}`,
`verificationSelfies/{uid}/{id}`, 5 MB) remains in `StoragePhotoFiles` and
`storage.rules` for when the Blaze plan is active.

Local rules tests (Firestore + Storage emulators):

```sh
firebase emulators:exec --only firestore,storage --project demo-kumee --config firebase.emulators.json "npm --prefix tool/firestore-tests test"
```

## Account essentials (0.4.0+6)

The saved-profile screen offers:

- **Edit profile**: the onboarding steps pre-filled with saved answers, then
  "Save changes". Gender and date of birth are shown read-only and cannot change
  after creation; the rules enforce this along with an unchanged `createdAt`.
- **Email verification**: registration sends a Firebase verification email (best
  effort). Unverified owners see a card to resend it or recheck after opening the
  link. Verification is not enforced yet; it is planned as a requirement before
  discovery.
- **Delete account**: requires the password (re-authentication) and a permanence
  confirmation, then deletes `profiles/{uid}` and `privateAccounts/{uid}` in one
  batch, then the Firebase Auth user. A failed final step reports a partial result
  and a retry continues without repeating finished work. Future data such as
  matches or messages will need server-side cleanup.

`AccountService` (implemented by `FirebaseAuthService`) holds these operations;
failures map to the same safe categories as authentication.

## Profile onboarding (0.3.0+5, schema v2)

After authentication, ProfileGate loads the owner's records from the server.
Missing records open a nine-step onboarding: basics (name, gender, date of birth),
roots (nationality, ethnicity), home (country of residence, city), private phone
number, work and education, faith and marital status, marriage intentions
(timeline, willingness to relocate), introduction, and review with the 18+
declaration. A complete schema v1 profile opens the same flow pre-filled with its
earlier answers and is upgraded in place. Read errors/offline access show retry;
they never imply a missing profile. Photos, profile editing and discovery are not
built yet.

Country pickers are searchable, pin common diaspora countries, and use
`lib/data/countries.g.dart`, generated from Unicode CLDR names (English and Somali)
and libphonenumber dial codes; regenerate it rather than editing by hand. The list
follows ISO 3166 (Somaliland is not listed separately yet). "Other" ethnicity and
profession answers require a short description.

`profiles/{uid}` holds only profile answers plus server timestamps.
`privateAccounts/{uid}` holds the adult declaration, date of birth (UTC date) and
E.164 phone number; neither is ever written to the profile document. The phone
number is not SMS-verified and the birth date is self-declared. Both documents are
written in one transaction with deterministic UID keys; retries return the saved
pair. Security rules allow owner get, paired v2 creation, paired updates (a v1
upgrade or an owner edit) that keep `createdAt`, with gender and birth date locked
on v2, and paired deletion; no list, discovery reads or privileged fields.

Firestore: default Native database in `eur3`, delete protection enabled, rules
deployed 2026-09-29. `firebase.json` pins the database and location. Always confirm
the database exists before a Firestore deploy, because a rules deploy can create a
missing database in the CLI's default region:

```sh
firebase firestore:databases:get "(default)" --project kumee-development
firebase deploy --only firestore:rules --project kumee-development
```

Do not use open/test-mode rules. No existing authentication users need deletion.

Local security verification (requires Java on PATH):

```sh
npm ci --prefix tool/firestore-tests --ignore-scripts
firebase emulators:exec --only firestore --project demo-kumee --config firebase.emulators.json "npm --prefix tool/firestore-tests test"
```

## Authentication UI checkpoint

Email/password and a 6-character registration minimum are user-confirmed.
Registration validates email, a minimum 6-character password, and confirmation;
login checks email and a nonempty password without applying registration rules.
Profiles and identity data are not collected here.

On configured mobile platforms, forms submit to Firebase Authentication.
Initialization failures and unsupported platforms retain an explicitly unavailable
service. Password fields clear before dispatch, controllers are disposed on exit,
and autofill saving is cancelled. Sign in includes Forgot password, which requests
a Firebase-hosted reset email. Email verification remains future work; the
signed-in screen grants no discovery, identity-verification or administrative privileges.

## Authentication service foundation

`AuthScreen` accepts an `AuthService`; its default `UnconfiguredAuthService`
cannot create an account or sign in. `AuthController` manages one request at a
time, safe failure categories, and disposal. Forms clear password fields before
dispatch, disable editing/submission while pending, and display localized
feedback. No provider exception text is shown or logged.

Only test files provide simulated services. FirebaseAuthService maps provider
errors to safe categories. Firebase authStateChanges drives session restoration
and navigation; form completion alone cannot open the signed-in screen. Identity
changes/sign-out reset the navigation stack. Session stream errors hide account
content and offer retry. Firebase SDK manages native session persistence; the
application does not store passwords or tokens itself.

## Firebase configuration checkpoint

Android and iOS are registered in `kumee-development` with the confirmed
identifier `com.kumee.app`. Actual client configuration was retrieved using
FlutterFire/Firebase CLI: `lib/firebase_options.dart`, Android
`google-services.json`, and iOS `GoogleService-Info.plist`. Firebase Core is
installed with Firebase Auth. main() initializes Firebase and supplies the real
adapter. Web and desktop Firebase apps are not configured and fail closed.
An initialization failure requires restarting the application to retry.

The user reports Email/Password enabled with Require/minimum 6; these console
settings still need independent verification. Never put service-account
credentials in this client.

## Authentication verification

Unit/widget tests cover adapter dispatch/error mapping and session UI using test
doubles. An isolated REST emulator check covers registration with six characters,
duplicate rejection, incorrect passwords, sign-in, password reset completion,
single-use reset codes, old/new password checks and fixture cleanup:

```sh
firebase emulators:exec --only auth --project demo-kumee --config firebase.emulators.json "node tool/verify_auth_emulator.mjs"
```

This script uses only localhost and a demo project; it is not a Flutter native SDK
end-to-end test. The normal mobile app targets kumee-development, not this emulator.
Device registration/login/restart/sign-out and live console policy verification
are separate from these checks. Provider/password policy was independently
verified: Email/Password enabled, Require/minimum 6. Device acceptance and real
reset-email delivery are still pending. No real account was created by automated
verification. Reset confirmations do not reveal whether an account exists.
Firebase-hosted email/page language follows project templates and may be English
even when the app is in Somali; app recovery screens support both languages.

## Installing the current development APK

Latest shareable APK: `build/app/outputs/flutter-apk/SHUKAANSI-0.6.0.apk` (release
mode, debug-signed). Source is at 0.7.0+11 (dashboard, Report/Block, suspension);
its rules were deployed on 2026-10-01. APKs are built only on request. The older 0.2.0 and KUMEE
builds can no longer create profiles.
Native initialization errors can still make builds unavailable and require device
diagnosis.

## UI redesign (0.9.0) and design sandbox

The redesigned Discover, Likes, Chats and My profile are part of the app.
For quick design checks with fictional, in-memory members (no backend calls,
unavailable in release builds):

```sh
flutter run -t lib/preview/preview_main.dart --dart-define=SHUKAANSI_PREVIEW=true
```

Plain `flutter run` starts the normal app. Spec, decisions and screenshots:
[docs/ui-redesign-spec.md](docs/ui-redesign-spec.md).

## Development

```sh
flutter pub get
flutter gen-l10n
dart format .
flutter analyze
flutter test
```

## Localization

Edit `lib/l10n/app_en.arb` and `lib/l10n/app_so.arb`, then run
`flutter gen-l10n`. Do not manually edit `lib/l10n/generated/`.
Keep message keys synchronized; the localization test checks resource coverage.

The app follows supported device locales until the user selects English or
Somali. Unsupported device languages fall back to English. Selection is held
in memory for the current app session, not saved across restarts. The language
picker intentionally shows both languages.

Flutter's installed SDK does not ship Somali Material/Cupertino translations.
`framework_localizations.dart` explicitly supplies English framework-control
labels for Somali; application messages are translated separately. Somali copy
and framework translations need native-speaker review before release. Both
languages use left-to-right layout. Native store/localization metadata is not
configured by this stage.

See `AGENTS.md` for persistent project-memory instructions.

