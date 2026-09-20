import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/markdown_parser.dart';
import '../providers/patch_notes_repository_provider.dart';

/// Notes d'une langue, lues une fois puis partagées.
///
/// L'écran appelait `loadPatchNotes()` depuis `build()`, donc fabriquait une
/// `Future` neuve à chaque reconstruction : `FutureBuilder`, qui voit une autre
/// future, repart de zéro — re-lecture de l'asset et bandeau « chargement » qui
/// remplace le contenu un instant, à chaque fois qu'un ancêtre se reconstruit.
/// Un `family` par langue : une seule `Future`, un contenu qui ne clignote pas.
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

    // Bandeau nu, sans Scaffold : la feuille PatchNotesDialog en fournit déjà un.
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

    // Dernière version = dernière clé du document.
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

            // What changed section — au-dessus des titres de section du fichier,
            // dont il doit rester visuellement le niveau supérieur.
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

/// Une ligne des notes : titre de section, élément à cocher, ou rien du tout.
///
/// Le fichier JSON est écrit en markdown, comme celui des conditions
/// d'utilisation : `### Titre` et `- élément` y sont de la syntaxe, jamais du
/// texte à imprimer. Les afficher tels quels — ce que cet écran faisait depuis
/// la v1.0.0 — pose un `### Nouvelles fonctionnalités` au même corps et à la
/// même coche que les éléments qu'il annonce : le parent ne voit plus la
/// hiérarchie. Le marqueur est donc interprété ici.
///
/// Le fichier n'est pas « nettoyé » pour autant : un rendu qui ne fonctionne que
/// si personne n'écrit jamais de markdown est le bug, pas le correctif.
class _PatchNotesItem extends StatelessWidget {
  const _PatchNotesItem({required this.item});

  /// Raw item text as stored in the JSON asset.
  final String item;

  /// Profondeur du titre (`#`, `##`, `###`), `null` pour une ligne ordinaire.
  ///
  /// Un `#Titre` sans espace n'est pas traité comme un titre : deviner une
  /// hiérarchie là où il manque un espace écrirait une intention du rédacteur
  /// qu'il n'a pas formulée.
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
    // Une entrée vide du tableau `items` ne doit pas produire une ligne
    // cochée sans texte — c'était le cas de la dernière entrée de chaque fichier.
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

/// Titre de section (`### Améliorations`), sans coche.
///
/// Cocher un titre laisserait croire que la section est une action accomplie ;
/// la hiérarchie se lit aussi à la taille, donc le niveau du `#` décide.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.level, required this.text});

  /// Profondeur du `#` dans le markdown : 1 à 3.
  final int level;

  /// Titre déjà débarrassé de ses marqueurs.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Niveau 1 au-dessus de niveau 2/3, et tous au-dessus du corps (bodyLarge)
    // des éléments qu'ils annoncèrent : une section plus petite que ses propres
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

/// Élément de liste : une coche et le texte du parent, markdown inline résolu.
class _CheckedItem extends StatelessWidget {
  const _CheckedItem({required this.text});

  /// Texte de l'élément, `- ` retiré et `**gras**` / `[lien](url)` résolus.
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
