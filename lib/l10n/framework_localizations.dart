import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Flutter has no Somali framework translations. Keep this fallback explicit
// until reviewed translations of framework controls are available.
class SomaliMaterialFallback
    extends LocalizationsDelegate<MaterialLocalizations> {
  const SomaliMaterialFallback();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(SomaliMaterialFallback old) => false;
}

class SomaliCupertinoFallback
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const SomaliCupertinoFallback();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(SomaliCupertinoFallback old) => false;
}
