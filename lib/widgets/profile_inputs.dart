import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'pressable.dart';

/// Background of a selected answer: a light brand-green wash on the surface.
Color selectedTint(ColorScheme colors) =>
    Color.alphaBlend(colors.primary.withValues(alpha: 0.10), colors.surface);

/// Group heading shared by the profile question widgets.
class QuestionLabel extends StatelessWidget {
  const QuestionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.text);
  final String? text;
  @override
  Widget build(BuildContext context) => text == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            text!,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        );
}

/// Single choice shown as full-width cards, each with an optional description.
class ChoiceCardsField<T> extends FormField<T> {
  ChoiceCardsField({
    super.key,
    required String label,
    required List<T> values,
    required String Function(T) title,
    String Function(T)? description,
    super.initialValue,
    required ValueChanged<T> onChanged,
    required String requiredMessage,
    bool enabled = true,
  }) : super(
         validator: (value) => value == null ? requiredMessage : null,
         builder: (field) {
           final colors = Theme.of(field.context).colorScheme;
           final text = Theme.of(field.context).textTheme;
           return Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               QuestionLabel(label),
               for (final value in values)
                 Padding(
                   padding: const EdgeInsets.only(bottom: 8),
                   child: _ChoiceCard(
                     key: ValueKey(value),
                     selected: field.value == value,
                     enabled: enabled,
                     title: title(value),
                     description: description?.call(value),
                     onTap: () {
                       field.didChange(value);
                       onChanged(value);
                     },
                     colors: colors,
                     text: text,
                   ),
                 ),
               _FieldError(field.errorText),
             ],
           );
         },
       );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.selected,
    required this.enabled,
    required this.title,
    required this.description,
    required this.onTap,
    required this.colors,
    required this.text,
  });
  final bool selected;
  final bool enabled;
  final String title;
  final String? description;
  final VoidCallback onTap;
  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    child: Pressable(
      enabled: enabled,
      child: Material(
        color: selected ? selectedTint(colors) : colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // Constant width: selection changes colour, never layout.
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            description!,
                            style: text.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ExcludeSemantics(
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? colors.primary : colors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Single choice shown as wrapping chips, for short labels.
class ChoiceChipsField<T> extends FormField<T> {
  ChoiceChipsField({
    super.key,
    required String label,
    required List<T> values,
    required String Function(T) title,
    super.initialValue,
    required ValueChanged<T> onChanged,
    required String requiredMessage,
    bool enabled = true,
  }) : super(
         validator: (value) => value == null ? requiredMessage : null,
         builder: (field) => Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             QuestionLabel(label),
             Wrap(
               spacing: 8,
               runSpacing: 8,
               children: [
                 for (final value in values)
                   ChoiceChip(
                     key: ValueKey(value),
                     label: Text(title(value)),
                     selected: field.value == value,
                     onSelected: enabled
                         ? (_) {
                             field.didChange(value);
                             onChanged(value);
                           }
                         : null,
                   ),
               ],
             ),
             _FieldError(field.errorText),
           ],
         ),
       );
}

/// A field that looks like a dropdown and opens a picker when tapped.
class _TapField extends StatelessWidget {
  const _TapField({
    required this.label,
    required this.valueText,
    required this.errorText,
    required this.enabled,
    required this.onTap,
    required this.icon,
  });
  final String label;
  final String? valueText;
  final String? errorText;
  final bool enabled;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: valueText == null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: errorText,
          errorMaxLines: 3,
          enabled: enabled,
          suffixIcon: ExcludeSemantics(child: Icon(icon)),
        ),
        child: valueText == null
            ? null
            : Text(valueText!, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ),
  );
}

class PickerOption<T> {
  const PickerOption({
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.searchText = '',
  });
  final T value;
  final String label;

  /// Decorative prefix such as a flag; hidden from screen readers.
  final String? leading;
  final String? trailing;

  /// Extra text matched by search (other-language names, codes).
  final String searchText;
}

/// Dropdown-style field with a searchable list, for long option lists.
class SearchPickerField<T> extends FormField<T> {
  SearchPickerField({
    super.key,
    required String label,
    required List<PickerOption<T>> options,
    List<T> suggested = const [],
    String Function(PickerOption<T>)? display,
    super.initialValue,
    required ValueChanged<T> onChanged,
    required String requiredMessage,
    bool enabled = true,
  }) : super(
         validator: (value) => value == null ? requiredMessage : null,
         builder: (field) {
           final selected = options
               .where((o) => o.value == field.value)
               .firstOrNull;
           return _TapField(
             label: label,
             valueText: selected == null
                 ? null
                 : display?.call(selected) ??
                       [selected.leading, selected.label].nonNulls.join('  '),
             errorText: field.errorText,
             enabled: enabled,
             icon: Icons.arrow_drop_down,
             onTap: () async {
               final picked = await showModalBottomSheet<T>(
                 context: field.context,
                 isScrollControlled: true,
                 useSafeArea: true,
                 showDragHandle: true,
                 builder: (_) => _PickerSheet<T>(
                   title: label,
                   options: options,
                   suggested: suggested,
                   current: field.value,
                 ),
               );
               if (picked != null) {
                 field.didChange(picked);
                 onChanged(picked);
               }
             },
           );
         },
       );
}

/// Opens the searchable list on its own, e.g. to add one of several values.
Future<T?> showSearchPicker<T>(
  BuildContext context, {
  required String title,
  required List<PickerOption<T>> options,
  List<T> suggested = const [],
  T? current,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _PickerSheet<T>(
    title: title,
    options: options,
    suggested: suggested,
    current: current,
  ),
);

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.suggested,
    required this.current,
  });
  final String title;
  final List<PickerOption<T>> options;
  final List<T> suggested;
  final T? current;
  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(PickerOption<T> option) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        option.label.toLowerCase().contains(q) ||
        option.searchText.toLowerCase().contains(q) ||
        (option.trailing?.toLowerCase().contains(q) ?? false);
  }

  Widget _tile(PickerOption<T> option) => ListTile(
    leading: option.leading == null
        ? null
        : ExcludeSemantics(
            child: Text(option.leading!, style: const TextStyle(fontSize: 24)),
          ),
    title: Text(option.label),
    trailing: option.trailing == null ? null : Text(option.trailing!),
    selected: option.value == widget.current,
    onTap: () => Navigator.of(context).pop(option.value),
  );

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final matches = widget.options.where(_matches).toList();
    final suggested = _query.isEmpty
        ? widget.suggested
              .map((v) => widget.options.where((o) => o.value == v).firstOrNull)
              .nonNulls
              .toList()
        : <PickerOption<T>>[];
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: s.profileSearch,
                  prefixIcon: const ExcludeSemantics(child: Icon(Icons.search)),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(child: Text(s.profileNoResults))
                  : ListView(
                      children: [
                        if (suggested.isNotEmpty) ...[
                          _header(s.profileSuggested),
                          ...suggested.map(_tile),
                          const Divider(),
                          _header(s.profileAllOptions),
                        ],
                        ...matches.map(_tile),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Date of birth as a UTC calendar date, picked with the platform date picker.
class BirthDateField extends FormField<DateTime> {
  BirthDateField({
    super.key,
    required String label,
    required String helper,
    super.initialValue,
    required DateTime today,
    required ValueChanged<DateTime> onChanged,
    required String? Function(DateTime?) validator,
    bool enabled = true,
  }) : super(
         validator: validator,
         builder: (field) {
           final latest = DateTime(today.year - 18, today.month, today.day - 1);
           final earliest = DateTime(today.year - 100, today.month, today.day);
           final value = field.value;
           return Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               _TapField(
                 label: label,
                 valueText: value == null
                     ? null
                     : MaterialLocalizations.of(field.context)
                           .formatFullDate(value),
                 errorText: field.errorText,
                 enabled: enabled,
                 icon: Icons.calendar_today_outlined,
                 onTap: () async {
                   final initial = value == null
                       ? DateTime(today.year - 25, 1, 1)
                       : DateTime(value.year, value.month, value.day);
                   final picked = await showDatePicker(
                     context: field.context,
                     initialDate: initial.isAfter(latest) ? latest : initial,
                     firstDate: earliest,
                     lastDate: latest,
                     initialDatePickerMode: DatePickerMode.year,
                     helpText: label,
                   );
                   if (picked != null) {
                     final date = DateTime.utc(
                       picked.year,
                       picked.month,
                       picked.day,
                     );
                     field.didChange(date);
                     onChanged(date);
                   }
                 },
               ),
               Padding(
                 padding: const EdgeInsets.only(top: 6, left: 4),
                 child: Text(
                   helper,
                   style: Theme.of(field.context).textTheme.bodySmall?.copyWith(
                     color: Theme.of(field.context)
                         .colorScheme
                         .onSurfaceVariant,
                   ),
                 ),
               ),
             ],
           );
         },
       );
}
