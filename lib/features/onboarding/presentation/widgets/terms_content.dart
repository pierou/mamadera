import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/markdown_parser.dart';

/// Terms & Conditions content widget without Scaffold.
///
/// Parses markdown manually to avoid heavy dependencies. Supports headers,
/// lists, bold, italic, links, and horizontal rules.
///
/// Used inside the acceptance dialog which provides the outer Scaffold
/// and the accept button.
class TermsContent extends StatelessWidget {
  const TermsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final assetPath = locale == 'en' ? 'assets/terms/terms_en.md' : 'assets/terms/terms_fr.md';

    return FutureBuilder<String>(
      future: rootBundle.loadString(assetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.expand(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.expand(
            child: Center(child: Text('Failed to load terms.')),
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
