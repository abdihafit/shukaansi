import 'package:flutter/widgets.dart';

class LocaleScope extends InheritedWidget {
  const LocaleScope({
    super.key,
    required this.locale,
    required this.selectLocale,
    required super.child,
  });

  final Locale? locale;
  final ValueChanged<Locale> selectLocale;

  static LocaleScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()!;

  @override
  bool updateShouldNotify(LocaleScope oldWidget) => locale != oldWidget.locale;
}
