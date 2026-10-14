import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/legal.dart';
import '../theme/tokens.dart';

/// Reads a bundled legal document in the app language. The text uses a small
/// Markdown subset: "# " title, "## " heading, "- " bullet, plain paragraphs.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.document});
  final LegalDocument document;

  static Future<void> open(BuildContext context, LegalDocument document) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LegalDocumentScreen(document: document),
        ),
      );

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  String? _language;
  late Future<String> _text;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (language == _language) return;
    _language = language;
    // Read once per language. Not cached: the text is small and only opened
    // occasionally.
    _text = DefaultAssetBundle.of(context)
        .loadString(widget.document.assetFor(language), cache: false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document == LegalDocument.terms
              ? s.termsOfUse
              : s.privacyPolicy,
        ),
      ),
      body: FutureBuilder<String>(
        future: _text,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(s.legalLoadFailed));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.s,
                AppSpacing.l,
                AppSpacing.xxl,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: _LegalText(snapshot.data!),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText(this.source);
  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyLarge?.copyWith(height: 1.5);
    final children = <Widget>[];
    for (final raw in source.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      if (line.startsWith('# ')) {
        children.add(
          Semantics(
            header: true,
            child: Text(
              line.substring(2),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.l),
            child: Semantics(
              header: true,
              child: Text(
                line.substring(3),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Text('•  ', style: body)),
                Expanded(child: Text(line.substring(2), style: body)),
              ],
            ),
          ),
        );
      } else {
        children.add(Text(line, style: body));
      }
      children.add(const SizedBox(height: AppSpacing.s));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
