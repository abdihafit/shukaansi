import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/countries.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/matrimonial_profile.dart';
import '../services/profile_service.dart';
import '../widgets/profile_inputs.dart';
import 'profile_labels.dart';
import '../theme/tokens.dart';
import '../widgets/shukaansi_ui.dart';
import '../widgets/brand/brand.dart';

class ProfileOnboarding extends StatefulWidget {
  const ProfileOnboarding({
    super.key,
    required this.uid,
    required this.service,
    required this.onCompleted,
    this.previous,
    this.initial,
    this.onCancel,
    this.today,
  });
  final String uid;
  final ProfileService service;
  final ValueChanged<ProfileComplete> onCompleted;

  /// Answers from a schema v1 profile being upgraded, if any.
  final LegacyProfile? previous;

  /// A saved profile being edited; gender and birth date are then read-only.
  final ProfileComplete? initial;

  /// Leaves editing without saving.
  final VoidCallback? onCancel;

  /// Overrides the current date in tests.
  final DateTime? today;
  @override
  State<ProfileOnboarding> createState() => _ProfileOnboardingState();
}

class _ProfileOnboardingState extends State<ProfileOnboarding> {
  static const _steps = 9;
  static const _reviewStep = _steps - 1;
  final _form = GlobalKey<FormState>();
  final _top = GlobalKey();
  late final MatrimonialProfile? _saved = widget.initial?.profile;
  late final PrivateDetails? _private = widget.initial?.details;
  late final _name = TextEditingController(
    text: _saved?.name ?? widget.previous?.name,
  );
  late final _city = TextEditingController(
    text: _saved?.city ?? widget.previous?.city,
  );
  late final _about = TextEditingController(
    text: _saved?.about ?? widget.previous?.about,
  );
  late final _ethnicityOther = TextEditingController(
    text: _saved?.ethnicityOther,
  );
  late final _professionOther = TextEditingController(
    text: _saved?.professionOther,
  );
  late final _phone = TextEditingController(text: _private?.nationalNumber);
  late ProfileGender? _gender = _saved?.gender ?? widget.previous?.gender;
  late MaritalStatus? _marital =
      _saved?.maritalStatus ?? widget.previous?.maritalStatus;
  late DateTime? _birthDate = _private?.birthDate;
  late String? _nationality = _saved?.nationality;
  late String? _residence = _saved?.residenceCountry;
  late String? _phoneCountry = _private?.phoneCountry;
  late Ethnicity? _ethnicity = _saved?.ethnicity;
  late Profession? _profession = _saved?.profession;
  late EducationLevel? _education = _saved?.education;
  late PracticeLevel? _practice = _saved?.practice;
  late MarriageTimeline? _timeline = _saved?.marriageTimeline;
  late Relocation? _relocation = _saved?.relocation;
  bool get _editing => widget.initial != null;
  // An existing profile has already made the 18+ declaration.
  late bool _adult = _editing;
  bool _adultError = false;
  bool _busy = false;
  bool _failed = false;
  // After a failed Continue, errors update live as answers are corrected.
  bool _submitted = false;
  int _step = 0;

  DateTime get _today => widget.today ?? DateTime.now();

  @override
  void dispose() {
    for (final controller in [
      _name,
      _city,
      _about,
      _ethnicityOther,
      _professionOther,
      _phone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  MatrimonialProfile get _profile => MatrimonialProfile(
    name: _name.text.trim(),
    gender: _gender!,
    nationality: _nationality!,
    residenceCountry: _residence!,
    city: _city.text.trim(),
    ethnicity: _ethnicity!,
    ethnicityOther: _ethnicity == Ethnicity.other
        ? _ethnicityOther.text.trim()
        : '',
    profession: _profession!,
    professionOther: _profession == Profession.other
        ? _professionOther.text.trim()
        : '',
    education: _education!,
    practice: _practice!,
    marriageTimeline: _timeline!,
    relocation: _relocation!,
    maritalStatus: _marital!,
    about: _about.text.trim(),
  );

  PrivateDetails get _details => PrivateDetails(
    birthDate: _birthDate!,
    phoneCountry: _phoneCountry!,
    phoneNumber: PrivateDetails.toE164(_phoneCountry!, _phone.text)!,
  );

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _failed = false;
      _submitted = false;
      // The phone step starts from the country the user lives in.
      if (step == 3) _phoneCountry ??= _residence;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final top = _top.currentContext;
      if (top != null && top.mounted) Scrollable.ensureVisible(top);
    });
  }

  Future<void> _next() async {
    if (_busy) return;
    final valid = _form.currentState!.validate();
    setState(() {
      _adultError = _step == _reviewStep && !_adult;
      _submitted = true;
    });
    if (!valid || _adultError) return;
    if (_step < _reviewStep) return _goTo(_step + 1);
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final saved = _editing
          ? await widget.service.update(widget.uid, _profile, _details)
          : await widget.service.save(
              widget.uid,
              _profile,
              _details,
              adultConfirmed: _adult,
            );
      if (mounted) widget.onCompleted(saved);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<PickerOption<String>> _countryOptions(
    BuildContext context, {
    bool dial = false,
  }) {
    final lang = Localizations.localeOf(context).languageCode;
    final options = [
      for (final c in Countries.all)
        PickerOption(
          value: c.code,
          label: c.name(lang),
          leading: c.flag,
          trailing: dial ? '+${c.dialCode}' : null,
          searchText: '${c.nameEn} ${c.nameSo} ${c.code}',
        ),
    ];
    return options..sort((a, b) => a.label.compareTo(b.label));
  }

  Widget _text(
    TextEditingController controller,
    String label,
    int min,
    int max, {
    int lines = 1,
    String? helper,
  }) {
    final s = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        enabled: !_busy,
        maxLength: max,
        minLines: lines,
        maxLines: lines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
          errorMaxLines: 3,
        ),
        validator: (value) =>
            MatrimonialProfile.validText((value ?? '').trim(), min, max)
            ? null
            : s.profileTextLength(min, max),
      ),
    );
  }

  List<Widget> _fields(BuildContext context, AppLocalizations s) {
    const gap = SizedBox(height: 24);
    final enabled = !_busy;
    switch (_step) {
      case 0:
        if (_editing) {
          return [
            _text(_name, s.profileName, 2, 50),
            _LockedDetails(
              rows: {
                s.profileGender: genderLabel(s, _gender!),
                s.profileDateOfBirth: MaterialLocalizations.of(context)
                    .formatFullDate(_birthDate!),
              },
              notice: s.profileLockedNotice,
            ),
          ];
        }
        return [
          _text(_name, s.profileName, 2, 50),
          ChoiceCardsField<ProfileGender>(
            key: const ValueKey('profile-gender'),
            label: s.profileGender,
            values: ProfileGender.values,
            title: (v) => genderLabel(s, v),
            initialValue: _gender,
            onChanged: (v) => setState(() => _gender = v),
            requiredMessage: s.fieldRequired,
            enabled: enabled,
          ),
          gap,
          BirthDateField(
            key: const ValueKey('profile-birth-date'),
            label: s.profileDateOfBirth,
            helper: s.profileDateOfBirthHint,
            initialValue: _birthDate,
            today: _today,
            onChanged: (v) => setState(() => _birthDate = v),
            validator: (v) => v == null
                ? s.fieldRequired
                : PrivateDetails.isAdult(v, _today)
                ? null
                : s.profileAdultRequired,
            enabled: enabled,
          ),
        ];
      case 1:
        return [
          SearchPickerField<String>(
            key: const ValueKey('profile-nationality'),
            label: s.profileNationality,
            options: _countryOptions(context),
            suggested: Countries.suggestedCodes,
            initialValue: _nationality,
            onChanged: (v) => setState(() => _nationality = v),
            requiredMessage: s.fieldRequired,
            enabled: enabled,
          ),
          gap,
          ChoiceCardsField<Ethnicity>(
            key: const ValueKey('profile-ethnicity'),
            label: s.profileEthnicity,
            values: Ethnicity.values,
            title: (v) => ethnicityLabel(s, v),
            initialValue: _ethnicity,
            onChanged: (v) => setState(() => _ethnicity = v),
            requiredMessage: s.fieldRequired,
            enabled: enabled,
          ),
          if (_ethnicity == Ethnicity.other) ...[
            const SizedBox(height: 12),
            _text(_ethnicityOther, s.profileEthnicityOtherLabel, 2, 40),
          ],
        ];
      case 2:
        return [
          SearchPickerField<String>(
            key: const ValueKey('profile-residence'),
            label: s.profileResidence,
            options: _countryOptions(context),
            suggested: Countries.suggestedCodes,
            initialValue: _residence,
            onChanged: (v) => setState(() => _residence = v),
            requiredMessage: s.fieldRequired,
            enabled: enabled,
          ),
          const SizedBox(height: 20),
          _text(_city, s.profileCity, 2, 56, helper: s.profileLocationNotice),
        ];
      case 3:
        return [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 136,
                child: SearchPickerField<String>(
                  key: const ValueKey('profile-phone-country'),
                  label: s.profileCountryCode,
                  options: _countryOptions(context, dial: true),
                  suggested: Countries.suggestedCodes,
                  display: (o) => '${o.leading} ${o.trailing}',
                  initialValue: _phoneCountry,
                  onChanged: (v) => setState(() => _phoneCountry = v),
                  requiredMessage: s.fieldRequired,
                  enabled: enabled,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const ValueKey('profile-phone'),
                  controller: _phone,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                    LengthLimitingTextInputFormatter(18),
                  ],
                  decoration: InputDecoration(
                    labelText: s.profilePhone,
                    border: const OutlineInputBorder(),
                    errorMaxLines: 3,
                  ),
                  validator: (value) =>
                      _phoneCountry == null ||
                          PrivateDetails.toE164(_phoneCountry!, value ?? '') !=
                              null
                      ? null
                      : s.profilePhoneInvalid,
                ),
              ),
            ],
          ),
        ];
      case 4:
        return [
          SearchPickerField<Profession>(
            key: const ValueKey('profile-profession'),
            label: s.profileProfession,
            options: [
              ...[
                for (final p in Profession.values)
                  if (p != Profession.other)
                    PickerOption(value: p, label: professionLabel(s, p)),
              ]..sort((a, b) => a.label.compareTo(b.label)),
              // "Other" stays last in every language.
              PickerOption(
                value: Profession.other,
                label: professionLabel(s, Profession.other),
              ),
            ],
            initialValue: _profession,
            onChanged: (v) => setState(() => _profession = v),
            requiredMessage: s.fieldRequired,
            enabled: enabled,
          ),
          if (_profession == Profession.other) ...[
            const SizedBox(height: 20),
            _text(_professionOther, s.profileProfessionOtherLabel, 2, 40),
          ] else
            gap,
          ChoiceChipsField<EducationLevel>(
            key: const ValueKey('profile-education'),
            label: s.profileEducation,
            values: EducationLevel.values,
            title: (v) => educationLabel(s, v),
            initialValue: _education,
            onChanged: (v) => setState(() => _education = v),
            requiredMessage: s.fieldRequired,
            enabled: enabled,
          ),
        ];
      case 5:
        return [
          ChoiceCardsField<PracticeLevel>(
            key: const ValueKey('profile-practice'),
            label: s.profilePractice,
            values: PracticeLevel.values,
            title: (v) => practiceLabel(s, v),
            description: (v) => practiceInfo(s, v),
            initialValue: _practice,
            onChanged: (v) => setState(() => _practice = v),
            requiredMessage: s.fieldRequired,
            enabled: enabled,
          ),
          gap,
          ChoiceChipsField<MaritalStatus>(
            key: const ValueKey('profile-marital'),
            label: s.profileMaritalStatus,
            values: MaritalStatus.values,
            title: (v) => maritalLabel(s, v),
            initialValue: _marital,
            onChanged: (v) => setState(() => _marital = v),
            requiredMessage: s.fieldRequired,
            enabled: enabled,
          ),
        ];
      case 6:
        return [
          ChoiceCardsField<MarriageTimeline>(
            key: const ValueKey('profile-timeline'),
            label: s.profileTimeline,
            values: MarriageTimeline.values,
            title: (v) => timelineLabel(s, v),
            initialValue: _timeline,
            onChanged: (v) => setState(() => _timeline = v),
            requiredMessage: s.fieldRequired,
            enabled: enabled,
          ),
          gap,
          ChoiceCardsField<Relocation>(
            key: const ValueKey('profile-relocation'),
            label: s.profileRelocation,
            values: Relocation.values,
            title: (v) => relocationLabel(s, v),
            initialValue: _relocation,
            onChanged: (v) => setState(() => _relocation = v),
            requiredMessage: s.fieldRequired,
            enabled: enabled,
          ),
        ];
      case 7:
        return [
          _text(
            _about,
            s.profileAbout,
            20,
            500,
            lines: 5,
            helper: s.profileAboutHint,
          ),
        ];
      default:
        return [
          ProfileSummary(profile: _profile, details: _details),
          if (!_editing)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _adult,
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                      _adult = v ?? false;
                      _adultError = false;
                    }),
              title: Text(s.profileAdultDeclaration),
            ),
          if (_adultError)
            Text(
              s.profileAdultRequired,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final updating = widget.previous != null;
    final (title, hint) = switch (_step) {
      0 => (s.profileStepBasicsTitle, s.profileStepBasicsHint),
      1 => (s.profileStepRootsTitle, s.profileStepRootsHint),
      2 => (s.profileStepHomeTitle, s.profileLocationNotice),
      3 => (s.profileStepPhoneTitle, s.profileStepPhoneHint),
      4 => (s.profileStepWorkTitle, s.profileStepWorkHint),
      5 => (s.profileStepFaithTitle, s.profileStepFaithHint),
      6 => (s.profileStepIntentionsTitle, s.profileStepIntentionsHint),
      7 => (s.profileStepAboutTitle, s.profilePrivacyNotice),
      _ => (s.profileReview, s.profileStepReviewHint),
    };
    final progress = s.profileStep(_step + 1, _steps);
    return Form(
      key: _form,
      autovalidateMode: _submitted
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            key: _top,
            children: [
              if (_step > 0)
                IconButton(
                  onPressed: _busy ? null : () => _goTo(_step - 1),
                  tooltip: s.profileBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              Expanded(
                child: Text(
                  progress,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_step + 1) / _steps,
              minHeight: 6,
              semanticsLabel: progress,
              color: colors.primary,
              backgroundColor: colors.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 28),
          if (updating && _step == 0) ...[
            Card(
              elevation: 0,
              color: colors.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.auto_awesome_outlined,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.profileUpdateNotice,
                        style: TextStyle(color: colors.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ..._fields(context, s),
          if (_failed) ...[
            const SizedBox(height: 20),
            Semantics(
              liveRegion: true,
              child: Text(
                s.profileSaveFailed,
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            onPressed: _next,
            loading: _busy,
            loadingLabel: s.authLoading,
            label: _step < _reviewStep
                ? s.profileContinue
                : _editing
                ? s.profileSaveChanges
                : updating
                ? s.profileUpdateSave
                : s.profileSave,
          ),
          if (_step > 0)
            TextButton(
              onPressed: _busy ? null : () => _goTo(_step - 1),
              child: Text(s.profileBack),
            ),
          if (widget.onCancel != null)
            TextButton(
              onPressed: _busy ? null : widget.onCancel,
              child: Text(s.profileCancelEdit),
            ),
        ],
      ),
    );
  }
}

/// Read-only answers that cannot change once the profile exists.
class _LockedDetails extends StatelessWidget {
  const _LockedDetails({required this.rows, required this.notice});
  final Map<String, String> rows;
  final String notice;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in rows.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(e.value, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Owner view of the saved profile, grouped into sections, with private
/// details kept in their own card. Headings reuse the onboarding step titles.
class ProfileSummary extends StatelessWidget {
  const ProfileSummary({
    super.key,
    required this.profile,
    required this.details,
  });
  final MatrimonialProfile profile;
  final PrivateDetails details;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    String withOther(String label, String other) =>
        other.isEmpty ? label : '$label: $other';
    final sections = <(IconData, String, Map<String, String>)>[
      (
        Icons.person_outline,
        s.profileSectionPublic,
        {
          s.profileName: profile.name,
          s.profileGender: genderLabel(s, profile.gender),
        },
      ),
      (
        Icons.diversity_3_outlined,
        s.profileStepRootsTitle,
        {
          s.profileNationality: countryName(context, profile.nationality),
          s.profileEthnicity: withOther(
            ethnicityLabel(s, profile.ethnicity),
            profile.ethnicityOther,
          ),
        },
      ),
      (
        Icons.place_outlined,
        s.profileStepHomeTitle,
        {
          s.profileResidence: countryName(context, profile.residenceCountry),
          s.profileCity: profile.city,
        },
      ),
      (
        Icons.work_outline,
        s.profileStepWorkTitle,
        {
          s.profileProfession: withOther(
            professionLabel(s, profile.profession),
            profile.professionOther,
          ),
          s.profileEducation: educationLabel(s, profile.education),
        },
      ),
      (
        Icons.mosque_outlined,
        s.profileStepFaithTitle,
        {
          s.profilePractice: practiceLabel(s, profile.practice),
          s.profileMaritalStatus: maritalLabel(s, profile.maritalStatus),
        },
      ),
      (
        Icons.favorite_border,
        s.profileStepIntentionsTitle,
        {
          s.profileTimeline: timelineLabel(s, profile.marriageTimeline),
          s.profileRelocation: relocationLabel(s, profile.relocation),
        },
      ),
      (
        Icons.format_quote_outlined,
        s.profileStepAboutTitle,
        {s.profileAbout: profile.about},
      ),
      (
        Icons.lock_outline,
        s.profileSectionPrivate,
        {
          s.profileDateOfBirth: MaterialLocalizations.of(context)
              .formatFullDate(details.birthDate),
          s.profilePhone: details.phoneNumber,
        },
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (icon, title, fields) in sections) ...[
          SectionCard(
            icon: icon,
            title: title,
            tinted: icon == Icons.lock_outline,
            child: ShukaansiFieldList(fields: fields),
          ),
          const SizedBox(height: AppSpacing.m),
        ],
      ],
    );
  }
}
