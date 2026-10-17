import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/markdown_parser.dart';
import '../providers/patch_notes_repository_provider.dart';

/// Notes from a language, read once and then shared.
///
/// The screen was calling the `loadPatchNotes()` function from within the `build()` function, which was creating a...
/// `Future` is rebuilt with each reconstruction: `FutureBuilder`, which sees a different outcome each time.
/// future: start from scratch – re-examine the assets and display a "loading" banner.
/// It temporarily replaces the content each time an ancestor is rebuilt.
/// One `family` per language: a single `Future`," and content that doesn't flicker.
final patchNotesProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, languageCode) async {
  final repository = ref.watch(patchNotesRepositoryProvider);
  return repository.loadPatchNotes(languageCode);
});

/// Screen displaying patch notes from JSON assets.
///
/// The locale → asset mapping (en/es/fr) lives in the patch notes repository,
/// exposed through `patchNotesRepositoryProvider`; this widget only forwards
/// the active language code and renders the result.
class PatchNotesScreen extends ConsumerWidget {
  const PatchNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final notesAsync = ref.watch(patchNotesProvider(locale));

    // A bare banner, without a Scaffold: the PatchNotesDialog component already provides one.
    if (notesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allNotes = notesAsync.value;
    if (notesAsync.hasError || allNotes == null || allNotes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l.patchNotesTitle)),
        body: Center(child: Text(context.l.patchNotesUnavailable)),
      );
    }

    // Latest version = latest key for the document.
    final latestVersion = allNotes.keys.last;
    final versionNotes = allNotes[latestVersion] as Map<String, dynamic>;
    final title = versionNotes['title'] as String? ?? context.l.patchNotesTitle;
    final releaseDate = versionNotes['releaseDate'] as String? ?? '';
    final items = (versionNotes['items'] as List? ?? []).cast<String>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXl,
          vertical: AppTheme.spacingLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version header
            _VersionHeader(
              version: latestVersion,
              releaseDate: releaseDate,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // "What changed" section — located above the section titles in the file.
            // of which he must remain visually aware of the higher level.
            Text(
              context.l.patchNotesWhatChanged,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Items list
            for (final item in items) _PatchNotesItem(item: item),
          ],
        ),
      ),
    );
  }
}

/// Version chip + release date row shown above the notes.
class _VersionHeader extends StatelessWidget {
  const _VersionHeader({
    required this.version,
    required this.releaseDate,
  });

  /// Latest version string, e.g. "1.1.0".
  final String version;

  /// Release date as stored in the JSON asset.
  final String releaseDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            version,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          releaseDate,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// A line of notes: this could be a section title, a checkbox item, or nothing at all.
///
/// The JSON file is written in Markdown, just like the file containing the terms and conditions.
/// Usage: `### Title` and `- element` are part of the syntax, and should never be used as actual content.
/// text to be printed. They were displayed exactly as they appeared — which is what this screen had been doing all along.
/// v1.0.0 — places a `### New Features` heading within the same section.
/// It's the same issue as the problems he describes: the parent can no longer see...
/// hierarchy. Therefore, the marker is interpreted in this context.
///
/// The file is not "cleaned up" yet: the rendering only works...
/// If no one ever writes in Markdown, then the problem isn't the fix, it's the underlying issue.
class _PatchNotesItem extends StatelessWidget {
  const _PatchNotesItem({required this.item});

  /// Raw item text as stored in the JSON asset.
  final String item;

  /// Heading level (`#`, `##`, `###`), or `null` for a regular line.
  ///
  /// A `#Title` without a space is not treated as a title: guessing a...
  /// In a hierarchical structure where a space is missing, it would indicate the author's intended meaning.
  /// that he has not yet expressed.
  static int? _headingLevel(String text) {
    var level = 0;
    while (level < text.length && text[level] == '#') {
      level++;
    }
    if (level == 0 || level >= text.length || text[level] != ' ') return null;
    return level > 3 ? 3 : level;
  }

  @override
  Widget build(BuildContext context) {
    final text = item.trim();
    // An empty entry in the `items` array should not result in a row being generated.
    // checked without any text — this was the case for the last entry in each file.
    if (text.isEmpty) return const SizedBox.shrink();

    final level = _headingLevel(text);
    if (level != null) {
      return _SectionHeader(
        level: level,
        text: parseInlineMarkdown(text.substring(level).trim()),
      );
    }

    final isBullet = text.startsWith('- ') || text.startsWith('* ');
    final body = isBullet ? text.substring(2).trim() : text;
    if (body.isEmpty) return const SizedBox.shrink();

    return _CheckedItem(text: parseInlineMarkdown(body));
  }
}

/// Section title (`### Improvements`), without a bullet point.
///
/// Checking a box would suggest that the section represents a completed task.
/// The hierarchy is also determined by size, so the level of the `#` symbol dictates the order.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.level, required this.text});

  /// Depth of the `#` symbol in Markdown: 1 to 3.
  final int level;

  /// The title has already been stripped of its identifying marks.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Level 1 is positioned above level 2/3, and all of them are located above the "bodyLarge" element.
    // elements that they announced: a section smaller than their own.
    // puces ne se voit pas.
    final base = switch (level) {
      1 => theme.textTheme.headlineSmall,
      _ => theme.textTheme.titleLarge,
    };

    return Padding(
      padding: EdgeInsets.only(
        top: level == 1 ? AppTheme.spacingLg : AppTheme.spacingMd,
        bottom: AppTheme.spacingSm,
      ),
      child: Text(
        text,
        style: base?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// List item: a checkmark and the text of the parent element, with inline Markdown formatting applied.
class _CheckedItem extends StatelessWidget {
  const _CheckedItem({required this.text});

  /// Text element: `-` removed, and `**bold**` / `[link](url)` formatting resolved.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
