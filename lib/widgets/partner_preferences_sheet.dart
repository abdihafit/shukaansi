import 'package:flutter/material.dart';

import '../application/discovery_controller.dart';
import '../data/countries.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../models/matrimonial_profile.dart';
import '../screens/profile_labels.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'profile_inputs.dart';

/// Opens the partner preferences editor; saves through [discovery] and
/// confirms. Returns true when saved.
Future<bool> editPartnerPreferences(
  BuildContext context,
  DiscoveryController discovery,
) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => PartnerPreferencesSheet(
      initial: discovery.filter,
      onSave: discovery.savePreferences,
    ),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).prefSaved)),
    );
  }
  return saved == true;
}

/// A short summary of saved preferences, e.g. "Ages 22–35 · 2 countries".
String preferencesSummary(AppLocalizations s, DiscoveryController discovery) {
  if (!discovery.hasPreferences) return s.prefNotSet;
  final f = discovery.filter;
  return [
    s.prefAges(f.minAge, f.maxAge),
    if (f.countries.isNotEmpty) s.prefCountryCount(f.countries.length),
  ].join(' · ');
}

class PartnerPreferencesSheet extends StatefulWidget {
  const PartnerPreferencesSheet({
    super.key,
    required this.initial,
    required this.onSave,
  });
  final DiscoveryFilter initial;

  /// Returns false when saving failed.
  final Future<bool> Function(DiscoveryFilter) onSave;
  @override
  State<PartnerPreferencesSheet> createState() =>
      _PartnerPreferencesSheetState();
}

class _PartnerPreferencesSheetState extends State<PartnerPreferencesSheet> {
  late RangeValues _ages = RangeValues(
    widget.initial.minAge.toDouble(),
    widget.initial.maxAge.toDouble(),
  );
  late final Set<String> _countries = {...widget.initial.countries};
  late final Set<MaritalStatus> _marital = {...widget.initial.maritalStatuses};
  late final Set<PracticeLevel> _practice = {...widget.initial.practices};
  bool _busy = false;
  bool _failed = false;

  Future<void> _addCountry() async {
    final s = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final picked = await showSearchPicker<String>(
      context,
      title: s.prefCountries,
      options: [
        for (final c in Countries.all)
          if (!_countries.contains(c.code))
            PickerOption(
              value: c.code,
              label: c.name(lang),
              leading: c.flag,
              searchText: '${c.nameEn} ${c.nameSo} ${c.code}',
            ),
      ]..sort((a, b) => a.label.compareTo(b.label)),
      suggested: Countries.suggestedCodes,
    );
    if (picked != null) setState(() => _countries.add(picked));
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final ok = await widget.onSave(
      DiscoveryFilter(
        minAge: _ages.start.round(),
        maxAge: _ages.end.round(),
        countries: _countries,
        maritalStatuses: _marital,
        practices: _practice,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  void _reset() => setState(() {
    _ages = RangeValues(
      DiscoveryFilter.minAllowedAge.toDouble(),
      DiscoveryFilter.maxAllowedAge.toDouble(),
    );
    _countries.clear();
    _marital.clear();
    _practice.clear();
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final min = _ages.start.round();
    final max = _ages.end.round();
    Widget chips<T>(
      String label,
      List<T> values,
      Set<T> selected,
      String Function(T) title,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuestionLabel(label),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final value in values)
              FilterChip(
                label: Text(title(value)),
                selected: selected.contains(value),
                onSelected: (on) => setState(
                  () => on ? selected.add(value) : selected.remove(value),
                ),
              ),
          ],
        ),
        if (selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              s.prefAnyAnswer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
    final full = _countries.length >= DiscoveryFilter.maxCountries;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                s.partnerPreferences,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            QuestionLabel(s.discoverAgeRange(min, max)),
            RangeSlider(
              values: _ages,
              min: DiscoveryFilter.minAllowedAge.toDouble(),
              max: DiscoveryFilter.maxAllowedAge.toDouble(),
              divisions:
                  DiscoveryFilter.maxAllowedAge - DiscoveryFilter.minAllowedAge,
              labels: RangeLabels('$min', '$max'),
              onChanged: (value) => setState(() => _ages = value),
            ),
            const SizedBox(height: AppSpacing.m),
            QuestionLabel(s.prefCountries),
            Text(
              s.prefCountriesHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final code in _countries)
                  InputChip(
                    avatar: ExcludeSemantics(
                      child: Text(Countries.byCode(code)?.flag ?? ''),
                    ),
                    label: Text(countryName(context, code)),
                    deleteButtonTooltipMessage: s.prefRemoveCountry(
                      countryName(context, code),
                    ),
                    onDeleted: () => setState(() => _countries.remove(code)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: Text(s.prefAddCountry),
                  onPressed: full ? null : _addCountry,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            chips(
              s.profileMaritalStatus,
              MaritalStatus.values,
              _marital,
              (v) => maritalLabel(s, v),
            ),
            const SizedBox(height: AppSpacing.xl),
            chips(
              s.filterPractice,
              PracticeLevel.values,
              _practice,
              (v) => practiceLabel(s, v),
            ),
            if (_failed) ...[
              const SizedBox(height: AppSpacing.l),
              Semantics(
                liveRegion: true,
                child: Text(
                  s.prefSaveFailed,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Pressable(
              enabled: !_busy,
              child: ElevatedButton(
                onPressed: _busy ? null : _save,
                child: Text(s.prefSave),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _reset,
              child: Text(s.discoverReset),
            ),
          ],
        ),
      ),
    );
  }
}
