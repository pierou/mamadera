import 'package:flutter/material.dart';

/// Parses a list of markdown lines into [TextSpan] objects.
///
/// Supports headers (#, ##, ###), lists (- or *), bold (**text**),
/// italic (*text*), links [text](url), and horizontal rules (---).
///
/// Used by the onboarding terms screens to render markdown assets, and by the
/// patch notes list, without adding a markdown-parsing dependency: `markdown`
/// was declared in pubspec for years and never imported once (it is gone as of
/// 1.1.0 — a declared dependency you do not use is still an audit surface).
/// If richer markdown is ever needed, a real span visitor belongs here, not a
/// silent re-add of that package.
List<TextSpan> parseMarkdownToTextSpans(List<String> lines, BuildContext context) {
  final spans = <TextSpan>[];
  final theme = Theme.of(context);
  final style = TextStyle(
    fontSize: 15,
    height: 1.6,
    color: theme.colorScheme.onSurface,
  );

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    if (line.isEmpty) {
      spans.add(const TextSpan(text: '\n'));
      continue;
    }

    if (line.startsWith('### ')) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      spans.addAll([
        TextSpan(
          text: line.substring(4),
          style: style.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const TextSpan(text: '\n\n'),
      ]);
    } else if (line.startsWith('## ')) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      spans.addAll([
        TextSpan(
          text: line.substring(3),
          style: style.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const TextSpan(text: '\n\n'),
      ]);
    } else if (line.startsWith('# ')) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      spans.addAll([
        TextSpan(
          text: line.substring(2),
          style: style.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const TextSpan(text: '\n\n'),
      ]);
    } else if ((line.startsWith('- ') || line.startsWith('* ')) && !line.startsWith('--')) {
      spans.addAll([
        const TextSpan(text: '  •  '),
        TextSpan(text: parseInlineMarkdown(line.substring(2)), style: style),
        const TextSpan(text: '\n'),
      ]);
    } else if (line.startsWith('---') || line.startsWith('***')) {
      spans.add(const TextSpan(text: '\n---\n'));
    } else {
      spans.addAll([
        TextSpan(text: parseInlineMarkdown(line), style: style),
        const TextSpan(text: '\n'),
      ]);
    }
  }

  return spans;
}

/// Parses inline markdown (bold, italic, links) into plain text.
///
/// Strips formatting markers and returns the plain text content.
/// For links, returns the link text (not the URL).
///
/// The patch notes rows run through this: the JSON is authored in markdown
/// (`- 🎚️ **Compact** mode inside the snooze dialog…`), and printing the
/// markers was the bug.
String parseInlineMarkdown(String input) {
  var result = input;

  // Handle inline bold: **text**
  result = result.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (match) => match.group(1) ?? '',
  );

  // Handle inline italic: *text*
  result = result.replaceAllMapped(
    RegExp(r'\*(.+?)\*'),
    (match) => match.group(1) ?? '',
  );

  // Handle links: [text](url)
  result = result.replaceAllMapped(
    RegExp(r'\[(.+?)\]\((.+?)\)'),
    (match) => match.group(1) ?? '',
  );

  return result;
}
