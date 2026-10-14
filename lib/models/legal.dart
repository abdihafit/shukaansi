/// Version of the Terms of Use and Privacy Policy bundled in assets/legal.
/// Raise it when either document changes in a way members must accept;
/// everyone who accepted an older version is asked again.
const currentLegalVersion = 2;

enum LegalDocument {
  terms('terms'),
  privacy('privacy');

  const LegalDocument(this._file);
  final String _file;

  /// Somali text for Somali, English otherwise.
  String assetFor(String languageCode) =>
      'assets/legal/${_file}_${languageCode == 'so' ? 'so' : 'en'}.md';
}
