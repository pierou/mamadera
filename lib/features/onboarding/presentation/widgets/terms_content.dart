import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/markdown_parser.dart';

/// Terms & Conditions content widget without Scaffold.
///
/// Parses markdown manually to avoid heavy dependencies. Supports headers,
/// lists, bold, italic, links, and horizontal rules.
///
/// Resolves the legal text from the asset matching the active locale (fr/en/es)
/// and falls back to the English document for any unsupported locale: English
/// is the safe universal fallback for legal text, French is not.
///
/// Used inside the acceptance dialog which provides the outer Scaffold
/// and the accept button.
class TermsContent extends StatelessWidget {
  const TermsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final assetPath = switch (locale) {
      'fr' => 'assets/terms/terms_fr.md',
      'es' => 'assets/terms/terms_es.md',
      _ => 'assets/terms/terms_en.md',
    };

    return FutureBuilder<String>(
      future: rootBundle.loadString(assetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.expand(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.expand(
            child: Center(child: Text(context.l.termsLoadingError)),
          );
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
