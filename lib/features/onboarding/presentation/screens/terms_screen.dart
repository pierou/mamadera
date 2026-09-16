import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/markdown_parser.dart';

/// Screen displaying the Terms & Conditions content from a markdown asset.
///
/// Parses markdown manually to avoid heavy dependencies. Supports headers,
/// lists, bold, italic, links, and horizontal rules.
class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.termsTitle),
        centerTitle: true,
      ),
      body: _TermsContent(assetPath: _termsAssetPathFor(locale)),
    );
  }

  /// Returns the localized terms markdown asset path.
  String _termsAssetPathFor(String locale) {
    switch (locale) {
      case 'en':
        return 'assets/terms/terms_en.md';
      case 'es':
        return 'assets/terms/terms_es.md';
      default:
        return 'assets/terms/terms_fr.md';
    }
  }
}

/// Loads and renders the terms markdown asset.
class _TermsContent extends StatelessWidget {
  const _TermsContent({required this.assetPath});

  /// Localized terms markdown asset path.
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(assetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(context.l.termsLoadingError));
        }

        final markdown = snapshot.data!;
        final lines = markdown.split('\n');
        final content = parseMarkdownToTextSpans(lines, context);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingXl,
            vertical: AppTheme.spacingLg,
          ),
          child: SelectableText.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              children: content,
            ),
          ),
        );
      },
    );
  }
}
