import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/health_label_resolver.dart';
import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Liste des sous-types santé — utilise l'enum HealthSubtype au lieu de strings
            ...HealthSubtype.values.map((subtype) {
              final isSelected = selectedType == subtype;
              return ListTile(
                leading: Icon(
                  switch (subtype.value) {
                    'nettoyage_yeux' => Icons.remove_red_eye,
                    'nettoyage_nombril' => Icons.circle,
                    'nettoyage_visage' => Icons.circle,
                    'nettoyage_nez' => Icons.circle,
                    'vitamine_d' => Icons.circle,
                    'vitamine_k' => Icons.circle,
                    _ => Icons.help_outline,
                  },
                  color: isSelected ? AppTheme.sante : null,
                ),
                title: Text(resolveHealthLabel(context, subtype)),
                trailing: selectedType == subtype
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(healthSubtypeDialogProvider.notifier).setSelected(subtype);
                },
              );
            }),

            const SizedBox(height: 20),

            DialogActionButtons(
              onCancelPressed: () => Navigator.pop(context),
              onConfirmPressed: () {
                final state = ref.read(healthSubtypeDialogProvider);
                if (state != null) {
                  if (context.mounted) {
                    Navigator.pop(context, {'subtype': state});
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l.healthSubtypeRequiredError)),
                  );
                }
              },
              cancelLabel: context.l.cancelButton,
              confirmLabel: context.l.confirmButton,
            ),
          ],
        ),
      ),
    );
  }
}
