import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Liste des sous-types santé — utilise l'enum HealthSubtype au lieu de strings
            ...HealthSubtype.values.map((subtype) {
              final isSelected = subtype == selectedType;
              return _buildHealthSubtypeTile(
                icon: switch (subtype.value) {
                  'nettoyage_yeux' => Icons.remove_red_eye,
                  'nettoyage_nombril' => Icons.circle,
                  'nettoyage_visage' => Icons.face,
                  'nettoyage_nez' => Icons.arrow_upward,
                  'vitamine_d' => Icons.wb_sunny,
                  'vitamine_k' => Icons.healing,
                  _ => Icons.help_outline,
                },
                label: subtype.label,
                isSelected: isSelected,
                onTap: () {
                  ref.read(healthSubtypeDialogProvider.notifier).setSelected(subtype);
                },
              );
            }),

            const SizedBox(height: 24),

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _onSubmit(context, ref),
                icon: const Icon(Icons.check, color: Colors.black),
                label: Text(context.l.saveButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sante,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSubtypeTile({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.sante),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.greenAccent) : null,
      tileColor: isSelected ? AppTheme.sante.withValues(alpha: 0.2) : null,
      onTap: onTap,
    );
  }

  void _onSubmit(BuildContext context, WidgetRef ref) {
    final state = ref.read(healthSubtypeDialogProvider);
    if (state != null) {
      Navigator.pop(context, {'subtype': state});
    } else {
      // Si aucun sous-type sélectionné, on affiche un message d'erreur.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.healthSubtypeRequiredError)),
      );
    }
  }
}


