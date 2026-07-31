import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/utils/markdown_parser.dart';

void main() {
  group('parseMarkdownToTextSpans', () {
    BuildContext buildTestContext(WidgetTester tester) {
      return tester.element(find.byType(SizedBox));
    }

    testWidgets('returns empty spans for empty input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans([], context);
      expect(spans, isEmpty);
    });

    testWidgets('adds newline span for empty line', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans([''], context);
      expect(spans.length, 1);
      expect(spans[0].text, '\n');
    });

    testWidgets('renders h3 header (###)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['### Subheading'], context);
      expect(spans.length, 2);
      final headingSpan = spans[0];
      expect(headingSpan.text, 'Subheading');
      expect(headingSpan.style?.fontSize, 18);
      expect(headingSpan.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('renders h2 header (##)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['## Heading'], context);
      expect(spans.length, 2);
      final headingSpan = spans[0];
      expect(headingSpan.text, 'Heading');
      expect(headingSpan.style?.fontSize, 20);
    });

    testWidgets('renders h1 header (#)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['# Title'], context);
      expect(spans.length, 2);
      final headingSpan = spans[0];
      expect(headingSpan.text, 'Title');
      expect(headingSpan.style?.fontSize, 24);
    });

    testWidgets('adds separator newline before heading when not first line', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['intro', '## Heading'], context);
      expect(spans.any((s) => s.text == '\n\n'), isTrue);
    });

    testWidgets('does not add separator for first-line heading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['## Heading'], context);
      expect(spans[0].text, 'Heading');
    });

    testWidgets('renders list item with - prefix', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['- Item one'], context);
      expect(spans.any((s) => s.text == '  •  '), isTrue);
      expect(spans.any((s) => s.text == '\n'), isTrue);
    });

    testWidgets('renders list item with * prefix', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['* Starred item'], context);
      expect(spans.any((s) => s.text == '  •  '), isTrue);
    });

    testWidgets('does not treat -- as a list item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['-- dashdash'], context);
      expect(spans.any((s) => s.text == '  •  '), isFalse);
    });

    testWidgets('renders horizontal rule ---', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['---'], context);
      expect(spans.length, 1);
      expect(spans[0].text, '\n---\n');
    });

    testWidgets('renders horizontal rule ***', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['***'], context);
      expect(spans.length, 1);
      expect(spans[0].text, '\n---\n');
    });

    testWidgets('renders regular paragraph with inline parsing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans(['Some text here'], context);
      expect(spans.length, 2);
      final contentSpan = spans[0];
      expect(contentSpan.text, 'Some text here');
    });

    testWidgets('handles mixed content correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const SizedBox.shrink()),
      );
      final context = buildTestContext(tester);
      final spans = parseMarkdownToTextSpans([
        '# Main Title',
        '',
        '- List item',
        'Regular paragraph',
        '---',
      ], context);
      expect(spans.isNotEmpty, isTrue);
      expect(spans.where((s) => s.text == '  •  ').isNotEmpty, isTrue);
      expect(
        spans.any((s) => s.style?.fontSize == 24),
        isTrue,
      );
    });
  });

  group('parseInlineMarkdown', () {
    test('returns input unchanged when no markdown present', () {
      final result = parseInlineMarkdown('plain text here');
      expect(result, 'plain text here');
    });

    test('strips bold markers **text**', () {
      final result = parseInlineMarkdown('this is **bold** text');
      expect(result, 'this is bold text');
    });

    test('strips italic markers *text*', () {
      final result = parseInlineMarkdown('this is *italic* text');
      expect(result, 'this is italic text');
    });

    test('replaces link with link text [text](url)', () {
      final result = parseInlineMarkdown(
        'click [here](https://example.com) for more',
      );
      expect(result, 'click here for more');
    });

    test('handles multiple inline formats in one string', () {
      final result = parseInlineMarkdown(
        '**bold** and *italic* and [link](url)',
      );
      expect(result, 'bold and italic and link');
    });

    test('handles empty input', () {
      final result = parseInlineMarkdown('');
      expect(result, '');
    });

    test('strips nested bold within paragraph', () {
      final result = parseInlineMarkdown('The **important** part is here');
      expect(result, 'The important part is here');
    });

    test('preserves text outside markdown markers', () {
      final result = parseInlineMarkdown('prefix **bolded** suffix');
      expect(result, 'prefix bolded suffix');
    });
  });
}
