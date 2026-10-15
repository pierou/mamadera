import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../home/presentation/widgets/quantity_picker_inline.dart';
import '../../domain/entities/growth_measurement.dart';
import '../../domain/entities/measure_kind.dart';
import 'measure_kind_accent.dart';

/// Résultat de la feuille d'édition d'une mesure, lu par l'historique.
sealed class MeasurementEditResult {
  const MeasurementEditResult();
}

/// La mesure a été corrigée (valeur, date, note).
final class MeasurementUpdated extends MeasurementEditResult {
  const MeasurementUpdated(this.measurement);

  /// La mesure corrigée, son id d'origine inclus.
  final GrowthMeasurement measurement;
}

/// La mesure a été supprimée.
final class MeasurementDeleted extends MeasurementEditResult {
  const MeasurementDeleted(this.id);

  final int id;
}

/// Feuille d'édition d'une mesure de croissance : on corrige la valeur, la
/// date ou la note d'une ligne existante — on n'en crée pas une autre — ou
/// on la supprime.
///
/// Le kind, l'unité et le bébé ne bougent jamais : c'est la même ligne qui
/// est corrigée. Une saisie hors plage suit la règle B5 — le nombre reste
/// affiché, l'erreur apparaît, Enregistrer se désactive, jamais de clamp.
class EditMeasurementSheet extends StatefulWidget {
  const EditMeasurementSheet({required this.measurement, super.key});

  final GrowthMeasurement measurement;

  /// Ouvre la feuille et renvoie le résultat (`null` si annulée).
  static Future<MeasurementEditResult?> show(
    BuildContext context, {
    required GrowthMeasurement measurement,
  }) {
    return showModalBottomSheet<MeasurementEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditMeasurementSheet(measurement: measurement),
    );
  }

  @override
  State<EditMeasurementSheet> createState() => _EditMeasurementSheetState();
}

class _EditMeasurementSheetState extends State<EditMeasurementSheet> {
  late double _value;
  bool _inRange = true;
  late DateTime _selectedDate;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    // La valeur affichée : celle de la ligne, ou la référence du type si le
    // chiffre est illisible (édition de l'en-tête dans ce cas). Le champ est
    // pré-rempli — c'est **l'édition** d'une mesure prise, pas la saisie d'une
    // nouvelle : la feuille de saisie, elle, démarre vide.
    _value = widget.measurement.value ?? widget.measurement.kind.defaultValue;
    _inRange = widget.measurement.kind.contains(_value);
    _selectedDate = widget.measurement.recordedAt;
    _noteController =
        TextEditingController(text: widget.measurement.notes ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_inRange) return;
    Navigator.of(context).pop(MeasurementUpdated(
      widget.measurement.copyWith(
        value: _value,
        recordedAt: _selectedDate,
        notes: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    ));
  }

  void _delete() {
    Navigator.of(context).pop(MeasurementDeleted(widget.measurement.id));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final kind = widget.measurement.kind;
    final title = switch (kind) {
      MeasureKind.poids => l.growthSheetEditTitleWeight,
      MeasureKind.taille => l.growthSheetEditTitleHeight,
      MeasureKind.temperature => l.growthSheetEditTitleTemperature,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        top: AppTheme.spacingMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingMd,
      ),
      child: SingleChildScrollView(
        // Comme la feuille de saisie : si la feuille dépasse l'écran (petit
        // téléphone, clavier ouvert), elle défile au lieu de couper — le bouton
        // d'enregistrement et celui de suppression doivent rester atteignables.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacingMd),
            QuantityPickerInline(
              unit: kind.displayUnit,
              min: kind.min,
              max: kind.max,
              divisions: kind.divisions,
              step: kind.step,
              decimals: kind.decimals,
              value: _value,
              accentColor: kind.accent,
              onValueChanged: (double value) {
                setState(() {
                  _value = value;
                  _inRange = true;
                });
              },
              onValueOutOfRange: (double value) {
                setState(() {
                  _value = value;
                  _inRange = false;
                });
              },
            ),
            if (!_inRange) ...[
              const SizedBox(height: 8),
              // `formatBound` : les bornes sont des entiers par construction, et la
              // feuille de saisie dit déjà « entre 200 et 20000 g ». Passer les
              // `double` bruts faisait « entre 200.0 et 20000.0 g » — deux phrases
              // pour la même erreur, avec des chiffres formatés différemment.
              Text(
                l.growthValueOutOfRange(
                  kind.formatBound(kind.min),
                  kind.formatBound(kind.max),
                  kind.displayUnit,
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppTheme.spacingMd),
            EventDateTimeField(
              value: _selectedDate,
              onChanged: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l.growthSheetNoteField,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.deleteButton,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                // `Expanded` + ellipse : sur un écran de 412 dp, les deux
                // libellés à leur taille naturelle débordaient de 6 px — un
                // bouton à moitié hors de l'écran n'est pas un bouton. L'action
                // principale prend le reste de la place, le libellé s'éclipse
                // avant qu'elle disparaisse.
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _inRange ? _save : null,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l.growthSheetSave,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
