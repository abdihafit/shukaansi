# SHUKAANSI UI redesign spec

Status: **in the app since 0.9.0+13 (2026-10-08).** The redesigned Discover,
Likes, Chats and My profile, the refined theme and the audit fixes for
onboarding, verification and plans are live in the normal app
(`lib/main.dart` → `ProfileGate`). The fictional-data preview below remains
only as a design sandbox for trying states quickly; it is not the product.

Last updated: 2026-10-08.
## 1. Design sandbox (optional, development only)

```sh
# Debug or profile build only. Needs the flag, otherwise a "Preview is off" screen is shown.
flutter run -t lib/preview/preview_main.dart --dart-define=SHUKAANSI_PREVIEW=true
```

- To go back to the normal app, run `flutter run` as usual (default entry point
  `lib/main.dart`). The preview has its own entry point, so nothing in the
  normal app needs switching off.
- To switch scenarios, tap the "Preview · fictional profiles" strip at the top.
  The sheet offers: populated, preferences not set, no matches, loading,
  network error, incomplete profile, awaiting review, and no activity. It also
  has a "Simulate Premium" switch.
- Safety (enforced in `lib/preview/preview_config.dart` and covered by
  `test/preview_test.dart`):
  - the preview needs both `SHUKAANSI_PREVIEW=true` and a non-release build;
    `previewAllowed()` returns false whenever `kReleaseMode` is true;
  - nothing in `lib/preview/` imports Firebase, Firestore, shared_preferences or
    share_plus (a test fails if it does);
  - every service is an in-memory fake that implements the real service
    interfaces, so the real controllers run unchanged. Nothing is read from or
    written to the backend: no payments, uploads or notifications. Sharing,
    email verification, sign-out and delete only show "Not available in the
    preview".
  - Messaging rules are the real ones: a match plus Wali approval where it is
    required. The fake chat service also refuses to send otherwise.

To re-create the review screenshots (32 + 3 audit PNGs in
`build/preview_screenshots/`, rendered with real Roboto and Material Icons):

```sh
flutter test tool/preview_screenshots/screenshots_test.dart
```

## 2. Fixtures

- Viewer: **Yusuf**, 31, London, IT. Eight fictional sisters aged 24–33 (Fardowsa,
  Sagal, Hibo, Ladan, Amina, Hodan, Nasra, Ifrah) in different cities and
  situations:
  - Sagal: Premium, not photo-verified;
  - Hibo: widowed, photos private;
  - Nasra: divorced, Premium.
- Portraits are drawn at runtime by a small PNG encoder
  (`synthetic_photos.dart`): an arch, a faceless silhouette and a hijab. No
  real people, no stock photos, no assets.
- Starting state:

  | Area | Who |
  |---|---|
  | Likes you | Sagal, Ladan |
  | You liked | Ifrah |
  | Matches | Amina (Wali approved, 4 messages), Nasra (Wali approved, 1 unread), Hodan (Wali **pending**) |

- Interaction rules:
  - Liking back a Premium member makes a match, with her Wali pending.
  - Two free members get "mutual, needs Premium".
  - Messages to an approved match get a canned reply after about 2 seconds.
- Prompts and interests are **concept fields**. They are not in the data model,
  appear only in the preview, and carry a "Concept" tag.

## 3. Visual system

All values live in `lib/theme/tokens.dart` and `lib/theme/app_theme.dart`
(`AppTheme.refinedLight` / `refinedDark`).

| Token | Value | Use |
|---|---|---|
| Page | `#F6F4EF` warm neutral (dark `#0E1F1A`) | Scaffold background |
| Surface | white (dark `#162B25`) | Section blocks, cards, nav bar, sheets |
| Primary | deep green `#064E43` (dark `#91D5BE`) | Actions, active nav, selected segment, checks |
| Accent | gold `#C99734` / `#8A6017` | Sparingly: Wali-pending ring, "Concept" tag, illustrations |
| Verified blue | `#1D72E8` | Photo-verified badge only |
| Outline | `#E7E2D8` | Hairlines only (dividers, action bar edge) |

- **Type:** one sans family (platform Roboto). Headline small 700, title 600–700,
  body 1.4–1.45 line height. App bar titles are an explicit 22/700, because
  component themes don't get localized text sizes.
- **Spacing:** 4/8 rhythm (`AppSpacing` xs 4 … xxxl 48), 16dp side gutter.
- **Radii:** 8 / 12 / 16 (cards, photos) / 20.
- **Elevation:** flat. Separation comes from white on warm neutral, not borders
  or shadows.
- **Touch:** at least 48dp everywhere (`AppSizes.touch`). Pass 56, Like 64.
- **Accessibility:**
  - semantic labels on photos ("Photo 1 of 3"), headers marked as headers,
    tooltips on icon buttons;
  - the photo viewer's fade is disabled when reduced motion is on;
  - layouts are tested at 360×690 with 1.4× text in English and Somali, light
    and dark.

## 4. Structure and screens

**Navigation:** 4 tabs. Discover | Likes | Chats | My profile. Matches no longer
has its own tab. New matches sit at the top of Chats. Badges: Likes = received
likes; Chats = unread + new matches.

### Discover (`lib/redesign/discover_view.dart`)

- One profile at a time.
- **Large portrait (4:5).** Nothing is drawn over the photo. The cover crop is
  weighted towards the top because there is no focal-point data yet. On short
  or large-text screens, the first photo gets slightly wider so the name always
  shows on the first screen.
- **Essentials below the photo:**
  - name, age and a "Photo verified" label. It only claims photo verification,
    and a tooltip explains this; it is never presented as identity
    verification.
  - location and marriage plans;
  - then white sections: About, prompt, photo 2, Background, Faith and family,
    Work and study, more photos, interests.
- **Pass / Like** sit in a fixed bar under the content, so they never cover a
  face, a name or text.
  - Pass shows a snackbar with Undo, placed above the bar.
  - Report / block are in the ⋮ menu next to the name.
- **App bar:** For you / New members switcher, a preferences button (with a dot
  when filters are set) and the activity bell.
- **States, each with a clear next step:**
  - loading skeleton;
  - network error → Retry;
  - not listed yet → checklist (verify email, add a photo), "Go to my profile";
  - preferences not set → set preferences (plus a dismissible inline nudge when
    people are still shown);
  - no matches → adjust preferences;
  - seen everyone → check again;
  - new members empty.

### Full photo viewer (`lib/redesign/photos.dart`)

- Black background, whole image (no crop), pinch-zoom 1–4×, swipe between photos.
- "Photo x of y" counter and a 48dp close button.
- Private (blurred) photos never open. The profile shows a "request access"
  note instead.

### Likes (`lib/redesign/likes_view.dart`)

- Segmented control: Liked you (n) / You liked (n). The selected segment uses the
  green wash.
- Grid of portrait tiles with name, verified tick and a status line ("Likes you",
  "Waiting for a reply", "Mutual"). Tile height follows the text size.

### Member page (`lib/redesign/member_page.dart`)

The same profile layout, with a bottom action bar that depends on the state:

| State | Actions |
|---|---|
| They like you | Not for me / Like back |
| You liked them | Withdraw |
| Mutual, needs Premium | View plans |
| Matched | Message, or the exact reason it is closed (e.g. "Waiting for their Wali's approval") |
| None | Like |

### Chats (`lib/redesign/chats_view.dart`)

- **"New matches" row** of avatars. A gold ring with an hourglass means waiting
  for a Wali.
- **Conversations list:** unread messages show in bold with a green dot. Where
  messaging is closed, the reason replaces the preview text.

### My profile (`lib/redesign/profile_home.dart`)

1. **Profile card:** avatar, name/age, city; Edit profile (primary) and Preview
   profile (stacked on large text); Manage photos.
2. **"Your progress":** three separate items that are never merged into one
   score.
   - Account (email);
   - Profile (visible in Discover);
   - Photo verification (not started / in review / verified / try again).
3. **Plans and preferences:** partner preferences, Wali card, membership.
4. **Settings:** language, legal, blocked members, sign out, delete account.

## 5. Decisions and honest limits

- **Interaction references (Hinge, Bumble, Muzz):** the patterns come from
  general product knowledge. No live apps were reviewed for this work.
- **"Awaiting review":** the backend has no profile-approval gate. The preview
  maps "incomplete" to the real not-listed rules (email + photo) and shows
  photo verification "In review" on Profile. No approval state was invented.
- **Not invented:** compatibility percentages, "active now", distance and
  identity checks.
- **Pass is local to the session.** It is not stored. Liking still uses the real
  rules.
- **Somali strings** for the 54 new keys need review by a native speaker.
- **Images:** synthetic placeholders only. How real photos look with the
  top-weighted crop still needs checking.

## 6. Future backend work (not done)

1. **Pass / hide:** a stored "passed" list (e.g. `users/{uid}/passed/{other}`,
   with rules and an expiry) so passed members stay hidden across sessions and
   devices.
2. **Prompts and interests:** new profile fields (schema version bump),
   moderation, onboarding steps and rules validation, before the "Concept" tag
   can go.
3. **Photo focal point:** store a focal point per photo (set at upload or by
   face detection), so crops never cut faces.
4. **Match alerts (done in 0.9.0):** production `ProfileGate._alert` also showed a "You matched
   with …" banner for matches made on the same device, right after the match
   sheet. The preview skips it. Apply the same skip in production when
   migrating.

## 7. What changed in the app (0.9.0)

- `main.dart` uses `AppTheme.refinedLight/refinedDark`; the test harness uses
  the same themes.
- `ProfileGate` shell: 4 tabs (Discover | Likes | Chats | My profile) built
  from `lib/redesign/`; Matches moved to the "New matches" row in Chats; Chats
  badge = unread + new matches; banners are cleared when switching tabs; the
  "you matched" banner is skipped for matches made on this device (the match
  sheet already said so).
- My profile: `ProfileHomeView` plus a "Your profile" row (full details incl.
  private ones). Manage photos = photos, photo privacy (sisters) and photo
  verification together; the Photo verification progress row opens it.
  Edit profile opens as its own page. Email verification opens from the Account
  progress row. Onboarding completion shows "MashaAllah, your profile is saved".
- Member page (from Likes, Chats and the chat header): "Not for me" returns to
  the list; a sister whose match waits for her own Wali gets "Invite your Wali".
- Discover: private photos note sits under the photo with Request, Requested +
  Cancel request, and a failure message; the preferences nudge wraps on small
  screens.
- Removed (superseded): `screens/discover_screen.dart`, `likes_screen.dart`,
  `matches_screen.dart`, `chats_screen.dart`, `member_profile_screen.dart`,
  `widgets/profile_overview_card.dart`, `widgets/profile_card_view.dart`.
- Screenshots of the real app: `flutter test tool/preview_screenshots/app_screenshots_test.dart`
  (`build/app_screenshots/`).
## 8. Audit of onboarding, verification and plans (fixed in 0.9.0 unless noted)

Seen through the preview (`audit-0x-*.png`).

### Onboarding / Edit profile (`screens/profile_onboarding.dart`, 9 steps)

- Content is centred vertically, so there is a large empty band above "Step 1
  of 9" on tall phones. Align it to the top.
- The title appears twice ("Edit profile" in the app bar and as the heading).
  In edit mode, keep one.
- The progress bar is gold. Use primary green and keep gold for accents.
- Outlined cards come from the old theme. Change to flat white sections.
- Nine steps is long for edits. Offer edit-by-section from Profile (jump
  straight to a step) and keep the linear flow for first-time setup only.

### Verification (`screens/verification_screen.dart`)

- Clear 3-step indicator and reassuring privacy copy. Good.
- The main action (take a selfie) is below the fold, under two cards and the
  tips. Put the action in a fixed bottom bar.
- The illustration is large. Make it smaller on short screens.
- The wording correctly says "confirm it's you" against the main photo. Keep it
  distinct from email verification everywhere.

### Plans / membership (`screens/plans_screen.dart`)

- Benefit rows are outlined cards that look tappable but aren't. Use a plain
  list with icons.
- "Browse Discover and show interest" is listed as a Premium benefit, but it is
  free. List only what the plan adds.
- "Continue with Premium" leads to a "coming soon" dialog, because payments
  wait for Blaze and plans are admin-granted for now. Say so before the tap
  (e.g. "Payments open soon").
- Tab order is Free | Premium | VIP. Check it against the earlier decision to
  show VIP first.

**Still open from this audit:** edit-by-section (jump straight to one onboarding step), a smaller verification illustration on short screens, the Plans tab order question, and a Profile signal for pending photo-access requests (sisters now manage them on Manage photos).
