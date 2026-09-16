import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';

/// Screen displaying patch notes from JSON assets.
class PatchNotesScreen extends ConsumerWidget {
  const PatchNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final assetPath = locale == 'en'
        ? 'assets/patch_notes/en.json'
        : 'assets/patch_notes/fr.json';

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadPatchNotes(assetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l.patchNotesTitle)),
            body: const Center(child: Text('No patch notes available')),
          );
        }

        final allNotes = snapshot.data!;
        // Get the latest version (last key in the map)
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

                // What changed section
                Text(
                  context.l.patchNotesWhatChanged,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
      },
    );
  }

  Future<Map<String, dynamic>> _loadPatchNotes(String path) async {
    final raw = await rootBundle.loadString(path);
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }
}

/// Version chip + release date row shown above the notes.
class _VersionHeader extends StatelessWidget {
  const _VersionHeader({
    required this.version,
    required this.releaseDate,
  });

  /// Latest version string, e.g. "1.0.1".
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

/// Single checkmarked bullet in the notes list.
class _PatchNotesItem extends StatelessWidget {
  const _PatchNotesItem({required this.item});

  /// Raw item text as stored in the JSON asset.
  final String item;

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
              item,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
