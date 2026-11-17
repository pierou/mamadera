import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/utils/health_label_resolver.dart';
import '../../../../shared/widgets/tracking_icons.dart';

/// Widget to display the subtypes of healthcare services.
///
/// The selection state is local to the [StatefulWidget]: it does not persist across rebuilds.
/// It closes the dialogue and doesn't transition smoothly from one topic to another.
class HealthSubtypeDialog extends StatefulWidget {
  const HealthSubtypeDialog({this.initialSubtype, super.key});

  /// Pre-selected care, from a notification tap (B15, D-R9): the tap says *which*
  /// care the reminder is about, the parent still chooses the moment and confirms.
  /// `null` = the ordinary empty sheet, which is every other way this opens.
  final HealthSubtype? initialSubtype;

  @override
  State<HealthSubtypeDialog> createState() => _HealthSubtypeDialogState();
}

class _HealthSubtypeDialogState extends State<HealthSubtypeDialog> {
  /// Seeded from [HealthSubtypeDialog.initialSubtype] when the sheet was opened by
  /// a reminder tap; the date is deliberately not pre-filled past "now", which is
  /// what a tap means ("just did it") and is already the default below.
  HealthSubtype? _selectedType;

  /// Date and time of the care routine, defaulted to the moment the sheet opened.
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSubtype;
  }

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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // List of health subtypes — uses the `HealthSubtype` enumeration instead of strings.
            ...HealthSubtype.values.map((subtype) {
              final isSelected = selectedType == subtype;
              return ListTile(
                leading: Icon(
                  HealthIcons.fromValue(subtype.value),
                  color: isSelected ? AppTheme.sante : null,
                ),
                title: Text(resolveHealthLabel(context, subtype)),
                trailing: selectedType == subtype
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary)
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
                    SnackBar(
                        content: Text(context.l.healthSubtypeRequiredError)),
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
