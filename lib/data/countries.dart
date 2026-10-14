part 'countries.g.dart';

/// A selectable country: ISO 3166-1 alpha-2 code, CLDR names and dial code.
class Country {
  const Country(this.code, this.nameEn, this.nameSo, this.dialCode);
  final String code;
  final String nameEn;
  final String nameSo;
  final int dialCode;

  String name(String languageCode) => languageCode == 'so' ? nameSo : nameEn;

  /// Flag from regional indicator symbols; purely decorative next to the name.
  String get flag =>
      String.fromCharCodes(code.codeUnits.map((unit) => 0x1F1E6 + unit - 0x41));
}

abstract final class Countries {
  static const List<Country> all = _countryData;
  static final Map<String, Country> _byCode = {
    for (final country in all) country.code: country,
  };

  /// Somali homeland, neighbours and the largest diaspora destinations.
  static const suggestedCodes = [
    'SO', 'KE', 'ET', 'DJ', 'GB', 'US', 'CA', 'SE', 'NO', 'NL', //
    'DE', 'FI', 'DK', 'AE', 'SA', 'TR', 'UG', 'ZA', 'AU',
  ];

  static Country? byCode(String? code) => code == null ? null : _byCode[code];
  static bool isValid(String? code) => _byCode.containsKey(code);
}
