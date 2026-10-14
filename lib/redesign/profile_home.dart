import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../application/discovery_controller.dart';
import '../application/media_controller.dart';
import '../application/membership_controller.dart';
import '../application/wali_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../models/profile_media.dart';
import '../screens/legal_consent_screen.dart';
import '../screens/plans_screen.dart';
import '../screens/profile_labels.dart';
import '../services/moderation_service.dart';
import '../services/profile_service.dart';
import '../theme/tokens.dart';
import '../services/app_lock_service.dart';
import '../widgets/app_lock_gate.dart';
import '../widgets/brand/brand.dart';
import '../widgets/shukaansi_ui.dart';
import '../widgets/language_tile.dart';
import '../widgets/partner_preferences_sheet.dart';
import '../widgets/safety_actions.dart';
import '../widgets/wali_card.dart';

/// Builds the card other members see from your own saved profile.
ProfileCard ownCard(
  String uid,
  ProfileComplete complete,
  MediaController media,
) => ProfileCard(
  uid: uid,
  profile: complete.profile,
  birthYearMonth:
      complete.details.birthDate.year * 100 + complete.details.birthDate.month,
  photoIds: media.photoIds,
  photosBlurred: false,
  verified: media.verification.status == VerificationStatus.verified,
);

/// My profile: the profile itself first (preview, edit, photos), then
/// progress kept as three separate things (account, profile, verification),
/// then preferences, Wali and membership, then settings.
class ProfileHomeView extends StatelessWidget {
  const ProfileHomeView({
    super.key,
    required this.uid,
    required this.complete,
    required this.media,
    required this.emailVerified,
    required this.discovery,
    required this.membership,
    required this.moderation,
    required this.share,
    required this.onPreview,
    required this.onEdit,
    required this.onManagePhotos,
    required this.onVerifyEmail,
    required this.onVerifyPhoto,
    required this.onSignOut,
    required this.onDeleteAccount,
    this.wali,
    this.today,
    this.onDetails,
  });
  final String uid;
  final ProfileComplete complete;
  final MediaController media;
  final bool emailVerified;
  final DiscoveryController discovery;
  final MembershipController membership;
  final WaliController? wali;
  final ModerationService moderation;
  final ShareText share;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onManagePhotos;
  final VoidCallback onVerifyEmail;
  final VoidCallback onVerifyPhoto;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  final DateTime? today;

  /// Your full profile including private details (phone, date of birth).
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final p = complete.profile;
    final now = today ?? DateTime.now();
    final birth = complete.details.birthDate;
    final age =
        now.year -
        birth.year -
        ((now.month < birth.month ||
                (now.month == birth.month && now.day < birth.day))
            ? 1
            : 0);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.s,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleMedium),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(s.navProfile),
        automaticallyImplyLeading: false,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([media, discovery]),
        builder: (context, _) {
          final main = mainPhotoOf(media.photoIds);
          final bytes = main == null ? null : media.images[main];
          // Built in full (it is short), so every row is reachable at once,
          // including by screen readers.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _CompletionAvatar(
                            photo: bytes,
                            done: [
                              emailVerified,
                              media.photoIds.isNotEmpty,
                              media.verification.status ==
                                  VerificationStatus.verified,
                              discovery.hasPreferences,
                            ],
                          ),
                          const SizedBox(width: AppSpacing.l),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    s.cardNameAge(displayName(p.name), age),
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.cardLocation(
                                    p.city,
                                    countryName(context, p.residenceCountry),
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.l),
                      // Side by side normally; stacked with large text so the
                      // labels never break mid-word.
                      Builder(
                        builder: (context) {
                          final preview = SecondaryButton(
                            onPressed: onPreview,
                            icon: Icons.visibility_outlined,
                            label: s.previewProfile,
                          );
                          final edit = PrimaryButton(
                            onPressed: onEdit,
                            icon: Icons.edit_outlined,
                            label: s.profileEdit,
                          );
                          if (MediaQuery.textScalerOf(context).scale(10) > 12) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                edit,
                                const SizedBox(height: AppSpacing.s),
                                preview,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: preview),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(child: edit),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.s),
                      SettingsTile(
                        icon: Icons.photo_library_outlined,
                        title: s.managePhotos,
                        subtitle: s.photosCount(
                          media.photoIds.length,
                          maxPhotos,
                        ),
                        onTap: onManagePhotos,
                      ),
                      if (onDetails != null)
                        SettingsTile(
                          icon: Icons.badge_outlined,
                          title: s.profileSectionPublic,
                          subtitle: s.profilePrivateDetails,
                          onTap: onDetails,
                        ),
                    ],
                  ),
                ),
                heading(s.profileProgressTitle),
                SectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Progress(
                        label: s.progressAccount,
                        done: emailVerified,
                        status: emailVerified
                            ? s.emailVerified
                            : s.progressAccountTodo,
                        onTap: emailVerified ? null : onVerifyEmail,
                      ),
                      const Divider(
                        indent: AppSpacing.l,
                        endIndent: AppSpacing.l,
                      ),
                      _Progress(
                        label: s.progressProfile,
                        done: discovery.listed,
                        status: discovery.listed
                            ? s.progressVisible
                            : s.progressAddPhoto,
                        onTap: discovery.listed ? null : onManagePhotos,
                      ),
                      const Divider(
                        indent: AppSpacing.l,
                        endIndent: AppSpacing.l,
                      ),
                      _Progress(
                        label: s.progressVerification,
                        done:
                            media.verification.status ==
                            VerificationStatus.verified,
                        status: switch (media.verification.status) {
                          VerificationStatus.verified => s.verifyStatusVerified,
                          VerificationStatus.pending => s.verifyStatusPending,
                          VerificationStatus.rejected => s.verifyStatusRejected,
                          VerificationStatus.none => s.verifyStatusNotStarted,
                        },
                        onTap:
                            media.verification.status ==
                                    VerificationStatus.none ||
                                media.verification.status ==
                                    VerificationStatus.rejected
                            ? onVerifyPhoto
                            : null,
                      ),
                    ],
                  ),
                ),
                // A gentle nudge while photo verification is still to do.
                if (media.verification.status == VerificationStatus.none ||
                    media.verification.status ==
                        VerificationStatus.rejected) ...[
                  const SizedBox(height: AppSpacing.m),
                  SectionCard(
                    tinted: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ShukaansiIconBadge(
                              icon: Icons.verified_outlined,
                              color: VerifiedBadge.color,
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.verifyNudgeTitle,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.verifyNudgeBody,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                        SecondaryButton(
                          label: s.verifyStart,
                          icon: Icons.verified_outlined,
                          onPressed: onVerifyPhoto,
                        ),
                      ],
                    ),
                  ),
                ],
                heading(s.yourPlans),
                SectionCard(
                  padding: EdgeInsets.zero,
                  child: SettingsTile(
                    icon: Icons.tune,
                    title: s.partnerPreferences,
                    subtitle: preferencesSummary(s, discovery),
                    onTap: () => editPartnerPreferences(context, discovery),
                  ),
                ),
                if (wali != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  WaliCard(controller: wali!, memberName: p.name, share: share),
                ],
                const SizedBox(height: AppSpacing.m),
                MembershipCard(membership: membership),
                heading(s.settingsTitle),
                const LanguageTile(),
                const _AppLockTile(),
                const SizedBox(height: AppSpacing.m),
                const LegalLinksCard(),
                const SizedBox(height: AppSpacing.m),
                BlockedMembersSection(
                  uid: uid,
                  moderation: moderation,
                  onChanged: discovery.markStale,
                ),
                const SizedBox(height: AppSpacing.s),
                TextButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: Text(s.signOut),
                ),
                TextButton.icon(
                  onPressed: onDeleteAccount,
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(s.accountDelete),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.label,
    required this.done,
    required this.status,
    this.onTap,
  });
  final String label;
  final bool done;
  final String status;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      minVerticalPadding: AppSpacing.m,
      leading: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done ? colors.primary : VerifiedBadge.color,
      ),
      title: Text(label),
      subtitle: Text(status),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Your photo inside a teal ring showing how complete your profile is, from
/// real checks only (email, a photo, photo verification, preferences).
class _CompletionAvatar extends StatelessWidget {
  const _CompletionAvatar({required this.photo, required this.done});
  final Uint8List? photo;
  final List<bool> done;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final percent = (done.where((d) => d).length * 100 / done.length).round();
    return Semantics(
      label: s.profileComplete(percent),
      excludeSemantics: true,
      child: SizedBox(
        width: 104,
        height: 116,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SizedBox.square(
              dimension: 104,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: percent / 100),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  color: colors.primary,
                  backgroundColor: colors.primaryContainer,
                ),
              ),
            ),
            Positioned(
              top: 8,
              child: ClipOval(
                child: SizedBox.square(
                  dimension: 88,
                  child: photo == null
                      ? ColoredBox(
                          color: colors.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 44,
                            color: colors.primary,
                          ),
                        )
                      : Image.memory(photo!, fit: BoxFit.cover),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.feature),
                  border: Border.all(
                    color: colors.surfaceContainerLowest,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: 2,
                  ),
                  child: Text(
                    '$percent%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Unlock with fingerprint, face or PIN": shown only when the phone has one
/// set up. Turning it on asks for a successful check first.
class _AppLockTile extends StatelessWidget {
  const _AppLockTile();

  @override
  Widget build(BuildContext context) {
    final lock = AppLockScope.maybeOf(context);
    if (lock == null || !lock.loaded || !lock.available) {
      return const SizedBox.shrink();
    }
    final s = AppLocalizations.of(context);
    Future<void> toggle(bool on) async {
      final messenger = ScaffoldMessenger.of(context);
      final changed = await lock.setEnabled(on, s.appLockEnableReason);
      if (!on || messenger.mounted == false) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              changed
                  ? s.appLockOn
                  : lock.lastResult == UnlockResult.unavailable
                  ? s.appLockUnavailable
                  : s.unlockFailed,
            ),
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: SectionCard(
        padding: EdgeInsets.zero,
        child: MergeSemantics(
          child: SettingsTile(
            icon: Icons.fingerprint,
            title: s.appLockTitle,
            subtitle: s.appLockSubtitle,
            onTap: lock.busy ? null : () => toggle(!lock.enabled),
            trailing: Switch(
              value: lock.enabled,
              onChanged: lock.busy ? null : toggle,
            ),
          ),
        ),
      ),
    );
  }
}
