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
    final assetPath = locale == 'en' ? 'assets/patch_notes/en.json' : 'assets/patch_notes/fr.json';

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
        final itemsRaw = versionNotes['items'] as List? ?? [];
        final items = itemsRaw.cast<String>();

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        latestVersion,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      releaseDate,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
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
                ...items.map(
                  (item) => Padding(
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
                  ),
                ),
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
