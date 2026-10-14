import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/profile_service.dart';
import '../theme/tokens.dart';
import '../widgets/pressable.dart';
import 'profile_onboarding.dart';

/// The owner's saved answers, grouped into section cards. Read only: the one
/// Edit profile action starts the existing edit flow.
class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({
    super.key,
    required this.complete,
    required this.onEdit,
  });
  final ProfileComplete complete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.profileSectionPublic)),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.s,
                AppSpacing.l,
                AppSpacing.xl,
              ),
              children: [
                ProfileSummary(
                  profile: complete.profile,
                  details: complete.details,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Pressable(
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(s.profileEdit),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
