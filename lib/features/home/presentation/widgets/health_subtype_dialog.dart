import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';

/// Notifier d'état pour le dialog de sous-types santé.
final healthSubtypeDialogProvider =
    NotifierProvider<HealthSubtypeDialogNotifier, HealthSubtype?>(
  HealthSubtypeDialogNotifier.new,
);

class HealthSubtypeDialogNotifier extends Notifier<HealthSubtype?> {
  @override
  HealthSubtype? build() => null;

  void setSelected(HealthSubtype subtype) {
    state = subtype;
  }

  void clear() {
    state = null;
  }
}

/// Widget pour afficher les sous-types de soins santé.
class HealthSubtypeDialog extends ConsumerWidget {
  const HealthSubtypeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(healthSubtypeDialogProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l.healthSubtypeDialogTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Liste des sous-types santé — utilise l'enum HealthSubtype au lieu de strings
            ...HealthSubtype.values.map((subtype) {
              return ListTile(
                leading: Icon(
                  switch (subtype.value) {
                    'nettoyage_yeux' => Icons.remove_red_eye,
                    'nettoyage_nombril' => Icons.circle,
                    'nettoyage_visage' => Icons.face,
                    'nettoyage_nez' => Icons.arrow_upward,
                    'vitamine_d' => Icons.wb_sunny,
                    'vitamine_k' => Icons.healing,
                    _ => Icons.help_outline,
                  },
                ),
                title: Text(_resolveHealthLabel(context, subtype)),
                trailing: selectedType == subtype
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: () {
                  ref.read(healthSubtypeDialogProvider.notifier).setSelected(subtype);
                },
              );
            }),

            const SizedBox(height: 20),

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final state = ref.read(healthSubtypeDialogProvider);
                  if (state != null) {
                    Navigator.pop(context, {'subtype': state});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l.healthSubtypeRequiredError)),
                    );
                  }
                },
                child: Text(context.l.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Résout le label localisé pour un HealthSubtype via son labelKey.
String _resolveHealthLabel(BuildContext context, HealthSubtype subtype) {
  switch (subtype.labelKey) {
    case 'healthNettoyageYeux':
      return context.l.healthNettoyageYeux;
    case 'healthNettoyageNombril':
      return context.l.healthNettoyageNombril;
    case 'healthNettoyageVisage':
      return context.l.healthNettoyageVisage;
    case 'healthNettoyageNez':
      return context.l.healthNettoyageNez;
    case 'healthVitamineD':
      return context.l.healthVitamineD;
    case 'healthVitamineK':
      return context.l.healthVitamineK;
    default:
      return subtype.label;
  }
}
