import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../screens/profile_labels.dart';
import '../theme/tokens.dart';
import '../widgets/brand/brand.dart';
import 'photos.dart';
import '../theme/app_theme.dart';

/// A question a member answers on their profile. CONCEPT ONLY: the profile
/// model has no prompts yet, so production passes none and nothing renders.
class ProfilePrompt {
  const ProfilePrompt(this.question, this.answer);
  final String question;
  final String answer;
}

/// Proposed profile content not yet in the data model (see
/// docs/ui-redesign-spec.md, "Future work"). Shown only in the preview.
class ProfileConcept {
  const ProfileConcept({this.prompts = const [], this.interests = const []});
  final List<ProfilePrompt> prompts;
  final List<String> interests;
}

/// One member's full profile, Hinge-style: a large portrait first, the
/// essentials right below it, their own words, then details in clean
/// sections with more photos in between. Scrolls vertically; nothing covers
/// the photos.
class MemberProfileView extends StatelessWidget {
  const MemberProfileView({
    super.key,
    required this.card,
    required this.photos,
    required this.today,
    this.concept,
    this.menu,
    this.privatePhotos,
    this.bottomPadding = AppSpacing.xl,
    this.leadPhotoMaxHeight,
  });
  final ProfileCard card;
  final MemberPhotos photos;
  final DateTime today;
  final ProfileConcept? concept;

  /// Report and block, next to the name.
  final Widget? menu;

  /// Shown under the first photo when her photos are private for this viewer.
  final Widget? privatePhotos;

  /// Room for anything floating below, such as Discover's actions.
  final double bottomPadding;

  /// Height the lead photo may fill (Discover: the visible area). Defaults
  /// to 70% of the screen.
  final double? leadPhotoMaxHeight;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = card.profile;
    final name = displayName(p.name);
    final ids = photos.ids;
    final prompts = concept?.prompts ?? const <ProfilePrompt>[];
    Widget gap([double h = AppSpacing.xl]) => SizedBox(height: h);
    final work = p.professionOther.isEmpty
        ? professionLabel(s, p.profession)
        : p.professionOther;
    final children = <Widget>[
      // The card: a large photo with name, age and place on a soft gradient
      // at the bottom (faces sit in the upper part), report/block on top.
      LayoutBuilder(
        builder: (context, box) {
          // About 70% of the screen tall, between 3:5 and 4:5 so faces are
          // never over-cropped.
          final cap =
              leadPhotoMaxHeight ?? MediaQuery.sizeOf(context).height * 0.7;
          final ratio = (box.maxWidth / cap).clamp(0.6, AppSizes.portrait);
          return _Hero(
            // Every photo in a swipeable carousel with page dots.
            pages: [
              for (final (i, id) in ids.indexed)
                PortraitPhoto(
                  photos: photos,
                  id: id,
                  semanticLabel: s.openPhoto(i + 1, ids.length),
                  onOpen: () => FullPhotoViewer.open(context, photos, i, name),
                  aspectRatio: ratio,
                  radius: AppRadius.hero,
                ),
            ],
            aspectRatio: ratio,
            title: s.cardNameAge(name, card.ageOn(today)),
            location: s.cardLocation(
              p.city,
              countryName(context, p.residenceCountry),
            ),
            verified: card.verified,
            menu: menu,
          );
        },
      ),
      ?privatePhotos,
      gap(AppSpacing.l),
      // The essentials at a glance; the verification pill says exactly what
      // was checked (photos, not identity).
      Wrap(
        spacing: AppSpacing.s,
        runSpacing: AppSpacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (card.verified) const PhotoVerifiedLabel(),
          InfoChip(
            icon: Icons.favorite_border,
            label: s.marriagePlans(timelineLabel(s, p.marriageTimeline)),
          ),
          InfoChip(icon: Icons.work_outline, label: work),
          InfoChip(
            icon: Icons.mosque_outlined,
            label: practiceLabel(s, p.practice),
          ),
        ],
      ),
      gap(),
      _Section(
        title: s.aboutName(name.split(' ').first),
        child: Text(p.about, style: theme.textTheme.bodyLarge),
      ),
      if (prompts.isNotEmpty) ...[gap(), _PromptCard(prompt: prompts.first)],
      gap(),
      _Section(
        title: s.sectionBackground,
        child: _Facts([
          (
            Icons.flag_outlined,
            s.profileNationality,
            countryName(context, p.nationality),
          ),
          (
            Icons.diversity_3_outlined,
            s.profileEthnicity,
            p.ethnicityOther.isEmpty
                ? ethnicityLabel(s, p.ethnicity)
                : p.ethnicityOther,
          ),
          (
            Icons.home_outlined,
            s.factLivesIn,
            countryName(context, p.residenceCountry),
          ),
        ]),
      ),
      gap(),
      _Section(
        title: s.profileStepFaithTitle,
        child: _Facts([
          (Icons.mosque_outlined, s.factPractice, practiceLabel(s, p.practice)),
          (
            Icons.person_outline,
            s.profileMaritalStatus,
            maritalLabel(s, p.maritalStatus),
          ),
          (
            Icons.flight_takeoff,
            s.factRelocation,
            relocationLabel(s, p.relocation),
          ),
        ]),
      ),
      gap(),
      _Section(
        title: s.profileStepWorkTitle,
        child: _Facts([
          (Icons.work_outline, s.profileProfession, work),
          (
            Icons.school_outlined,
            s.profileEducation,
            educationLabel(s, p.education),
          ),
        ]),
      ),
      for (final prompt in prompts.skip(1)) ...[
        gap(),
        _PromptCard(prompt: prompt),
      ],
      if ((concept?.interests ?? const []).isNotEmpty) ...[
        gap(),
        _Section(
          title: s.interestsTitle,
          concept: true,
          child: Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final interest in concept!.interests)
                InfoChip(label: interest),
            ],
          ),
        ),
      ],
      SizedBox(height: bottomPadding),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// "Photo verified": the reviewer matched a private selfie to the photos.
/// Deliberately not "Verified": it does not check identity documents.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.concept = false,
  });
  final String title;
  final Widget child;
  final bool concept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.l + AppSpacing.xs),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
                if (concept) const _ConceptTag(),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            child,
          ],
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts(this.facts);
  final List<(IconData, String, String)> facts;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        for (final (i, (icon, label, value)) in facts.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.m),
          Semantics(
            label: '$label: $value',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: colors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(value, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt});
  final ProfilePrompt prompt;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    prompt.question,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const _ConceptTag(),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              prompt.answer,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marks content that exists only in the preview (not in the data model).
class _ConceptTag extends StatelessWidget {
  const _ConceptTag();
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        s.conceptLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The lead photo with the essentials over a soft bottom gradient.
class _Hero extends StatefulWidget {
  const _Hero({
    required this.pages,
    required this.aspectRatio,
    required this.title,
    required this.location,
    required this.verified,
    this.menu,
  });
  final List<Widget> pages;
  final double aspectRatio;
  final String title;
  final String location;
  final bool verified;
  final Widget? menu;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final widget = this.widget;
    const shadow = [Shadow(color: AppColors.photoShadow, blurRadius: 8)];
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Stack(
        children: [
          if (widget.pages.length > 1)
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: PageView(
                controller: _pages,
                onPageChanged: (p) => setState(() => _page = p),
                children: widget.pages,
              ),
            )
          else if (widget.pages.length == 1)
            widget.pages.first
          else
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.primaryContainer, colors.primary],
                  ),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 96,
                  color: colors.onPrimary.withValues(alpha: 0.6),
                ),
              ),
            ),
          // Text sits on a gradient so it reads on any photo; taps pass
          // through to the photo.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), AppColors.photoScrim],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.xxxl,
                    AppSpacing.l,
                    AppSpacing.l,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Semantics(
                              header: true,
                              child: Text(
                                widget.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppColors.onPhoto,
                                  fontWeight: FontWeight.w800,
                                  shadows: shadow,
                                ),
                              ),
                            ),
                          ),
                          if (widget.verified) ...[
                            const SizedBox(width: AppSpacing.s),
                            // Decorative here; the pill below says what was
                            // verified.
                            const ExcludeSemantics(child: VerifiedBadge()),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 18,
                            color: AppColors.onPhoto,
                            shadows: shadow,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              widget.location,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onPhoto,
                                shadows: shadow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Page dots: which photo is showing, at the top like a story bar.
          if (widget.pages.length > 1)
            Positioned(
              top: AppSpacing.m,
              left: AppSpacing.xxxl,
              right: AppSpacing.xxxl,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppColors.onPhoto
                                : AppColors.onPhoto.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.photoShadow,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.menu != null)
            Positioned(
              top: AppSpacing.s,
              right: AppSpacing.s,
              child: Material(
                color: AppColors.photoScrim.withValues(alpha: 0.35),
                shape: const CircleBorder(),
                child: IconTheme.merge(
                  data: const IconThemeData(color: AppColors.onPhoto),
                  child: widget.menu!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
