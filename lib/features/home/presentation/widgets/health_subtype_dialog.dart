import 'package:flutter/material.dart';

import '../../../../../shared/utils/health_label_resolver.dart';
import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_icons.dart';

/// Widget pour afficher les sous-types de soins santé.
///
/// L'état de sélection est local au [StatefulWidget] : il ne survit pas à la
/// fermeture du dialog et ne fuit pas d'une ouverture à l'autre.
class HealthSubtypeDialog extends StatefulWidget {
  const HealthSubtypeDialog({super.key});

  @override
  State<HealthSubtypeDialog> createState() => _HealthSubtypeDialogState();
}

class _HealthSubtypeDialogState extends State<HealthSubtypeDialog> {
  HealthSubtype? _selectedType;

  /// Date and time of the care routine, defaulted to the moment the sheet opened.
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selectedType = _selectedType;

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
                  HealthIcons.fromValue(subtype.value),
                  color: isSelected ? AppTheme.sante : null,
                ),
                title: Text(resolveHealthLabel(context, subtype)),
                trailing: selectedType == subtype
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedType = subtype);
                },
              );
            }),

            const SizedBox(height: 20),

            EventDateTimeField(
              value: _selectedDate,
              onChanged: (date) => setState(() => _selectedDate = date),
            ),

            const SizedBox(height: 20),

            DialogActionButtons(
              onCancelPressed: () => Navigator.pop(context),
              onConfirmPressed: () {
                final state = _selectedType;
                if (state != null) {
                  if (context.mounted) {
                    Navigator.pop(context, {
                      'subtype': state,
                      'timestamp': _selectedDate,
                    });
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
