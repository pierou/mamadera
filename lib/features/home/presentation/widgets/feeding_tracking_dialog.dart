import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/unit_localization.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../../shared/domain/entities/quantity_unit.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_icons.dart';
import 'quantity_picker_inline.dart';

/// A dialog for tracking feeding events with subtype selection and quantity.
///
/// Contains:
/// - Feeding subtype chip selector (natural/artificial/solid) at the top
/// - Unit toggle, **only** for `natural`: a feed at the breast is timed
///   (minutes), expressed milk is measured (millilitres), and the same parent
///   does both the same day
/// - Quantity picker whose unit and range follow the selected unit
/// - Date and time of the feed (defaults to now)
/// - Confirm button that returns (feedingSubtype, unit, quantity, timestamp)
class FeedingTrackingDialog extends ConsumerStatefulWidget {
  const FeedingTrackingDialog({super.key});

  @override
  ConsumerState<FeedingTrackingDialog> createState() =>
      _FeedingTrackingDialogState();
}

class _FeedingTrackingDialogState extends ConsumerState<FeedingTrackingDialog> {
  late FeedingSubtype _selectedSubtype;

  /// Unit of the quantity being entered. `min` at the open: a breastfeed is
  /// timed, a bottle is measured.
  late QuantityUnit _unit;
  double _selectedQuantity = 0;

  /// La quantité est remise à 0 quand l'unité change, et le dialog le dit.
  bool _unitResetNotice = false;

  /// Nombre saisi hors des bornes ; `null` = dans la plage (ou rien saisi).
  double? _outOfRange;

  /// Date and time of the feed. Defaulted once at open time: the dialog is
  /// rebuilt on every slider tick, so a plain field initialiser keeps the
  /// displayed "now" stable while the parent is choosing.
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedSubtype = FeedingSubtype.natural; // Default to breast milk
    _unit = QuantityUnit.min;
  }

  void _onQuantityChanged(double quantity) {
    setState(() {
      _selectedQuantity = quantity;
      _outOfRange = null;
    });
  }

  /// Unit carried by a subtype: grams for solids, minutes at the breast,
  /// millilitres for a bottle. Fixed for every subtype except `natural`,
  /// where the parent chooses.
  static QuantityUnit _unitFor(FeedingSubtype subtype) => switch (subtype) {
        FeedingSubtype.natural => QuantityUnit.min,
        FeedingSubtype.artificial => QuantityUnit.ml,
        FeedingSubtype.solid => QuantityUnit.g,
      };

  bool get _inRange => _outOfRange == null;

  /// Sélection d'un sous-type : l'unité suit, et **le nombre ne survit pas à
  /// un changement d'unité**.
  ///
  /// 20 ml n'est pas 20 minutes, et 20 min n'est pas 20 g. Conserver le
  /// nombre en changeant l'étiquette, c'est exactement le défaut que cette
  /// version supprime : le champ repart à 0 et le dialog le dit en inline.
  void _selectSubtype(FeedingSubtype subtype) {
    setState(() {
      _selectedSubtype = subtype;
      final nextUnit = _unitFor(subtype);
      if (nextUnit != _unit) {
        _unit = nextUnit;
        _selectedQuantity = 0;
        _unitResetNotice = true;
      }
      _outOfRange = null;
    });
  }

  /// Choix du parent au sein (ml ↔ min) : même règle, aucun nombre ne change
  /// d'unité en douceur.
  void _selectUnit(QuantityUnit unit) {
    if (unit == _unit) return;
    setState(() {
      _unit = unit;
      _selectedQuantity = 0;
      _unitResetNotice = true;
      _outOfRange = null;
    });
  }

  /// Bornes et pas du picker, **en fonction de l'unité choisie** (plan
  /// v1.2.1) : `ml` 0–300 par 10, `min` 0–120 par 1, `g` 0–1000 par 5.
  /// Une tétée de 40 minutes ne se saisit pas sur une plage de biberon, et
  /// un volume de 5 ml se rate à un cran de 10.
  ///
  /// La paire [SliderPair] (B2) accompagne chaque unité : le slider grossier
  /// amène au voisinage, le fin règle le dernier cran, le stepper ± reste le
  /// nudge d'un quantum.
  ({double min, double max, int divisions, double step, SliderPair sliderPair})
      get _pickerSpec =>
          switch (_unit) {
            QuantityUnit.ml => (
                  min: 0,
                  max: 300,
                  divisions: 30,
                  step: 10,
                  sliderPair: const (coarseStep: 50, fineSpan: 50, fineStep: 10)
                ),
            QuantityUnit.min => (
                  min: 0,
                  max: 120,
                  divisions: 120,
                  step: 1,
                  sliderPair: const (coarseStep: 30, fineSpan: 30, fineStep: 5)
                ),
            QuantityUnit.g => (
                  min: 0,
                  max: 1000,
                  divisions: 200,
                  step: 5,
                  sliderPair: const (coarseStep: 50, fineSpan: 50, fineStep: 10)
                ),
          };

  /// L'unité affichée : celle de la ligne en cours de saisie, résolue depuis
  /// la locale — jamais un `'ml'` écrit dans le widget.
  String _feedingUnit(BuildContext context) =>
      quantityUnitLabel(context, _unit);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              context.l.feedingDialogTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Feeding subtype selector
            Text(
              context.l.feedingSubtypeLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeedingSubtype.natural.icon, size: 18),
                        Flexible(
                          child: Text(
                            context.l.feedingSubtypeNatural,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    selected: _selectedSubtype == FeedingSubtype.natural,
                    onSelected: (_) => _selectSubtype(FeedingSubtype.natural),
                    selectedColor: AppTheme.miam.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeedingSubtype.artificial.icon, size: 18),
                        Flexible(
                          child: Text(
                            context.l.feedingSubtypeArtificial,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    selected: _selectedSubtype == FeedingSubtype.artificial,
                    onSelected: (_) =>
                        _selectSubtype(FeedingSubtype.artificial),
                    selectedColor: AppTheme.miam.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeedingSubtype.solid.icon, size: 18),
                        Flexible(
                          child: Text(
                            context.l.feedingSolid,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    selected: _selectedSubtype == FeedingSubtype.solid,
                    onSelected: (_) => _selectSubtype(FeedingSubtype.solid),
                    selectedColor: AppTheme.miam.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Unité — le sein seul a deux unités légitimes : téter se compte
            // en minutes, tirer se compte en millilitres, et la même mère fait
            // les deux le même jour. Les autres sous-types restent figés.
            if (_selectedSubtype == FeedingSubtype.natural) ...[
              Text(
                context.l.feedingUnitLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<QuantityUnit>(
                segments: [
                  ButtonSegment(
                    value: QuantityUnit.ml,
                    label: Text(context.l.feedingUnitMl),
                  ),
                  ButtonSegment(
                    value: QuantityUnit.min,
                    label: Text(context.l.feedingUnitMin),
                  ),
                ],
                selected: {_unit},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => _selectUnit(selection.first),
              ),
              const SizedBox(height: 24),
            ],

            // Le message de remise à 0 sort du bloc `natural` : passer de
            // « Lait Maternel » (min) à « Solide » (g) remet aussi la quantité
            // à 0, et une remise à 0 silencieuse est le défaut que v1.2.1
            // existe à supprimer.
            if (_unitResetNotice) ...[
              const SizedBox(height: 8),
              Text(
                context.l.feedingUnitReset,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
            ],

            // Quantity section
            Text(
              context.l.feedingQuantityLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            QuantityPickerInline(
              unit: _feedingUnit(context),
              min: _pickerSpec.min,
              max: _pickerSpec.max,
              divisions: _pickerSpec.divisions,
              // Stepper aligné sur le pas du slider pour l'unité courante.
              step: _pickerSpec.step,
              sliderPair: _pickerSpec.sliderPair,
              value: _selectedQuantity,
              onValueChanged: _onQuantityChanged,
              // Une saisie hors plage ne se tait plus (BACKLOG B5) : le nombre
              // du parent reste à l'écran, l'erreur s'affiche, et Enregistrer
              // reste désactivé. Jamais de `clamp` : corriger un nombre de
              // parent sans le lui dire est ce que cette app refuse.
              onValueOutOfRange: (value) => setState(() {
                _selectedQuantity = value;
                _outOfRange = value;
              }),
            ),

            if (!_inRange) ...[
              const SizedBox(height: 8),
              Text(
                context.l.feedingValueOutOfRange(
                  _pickerSpec.min.toInt().toString(),
                  _pickerSpec.max.toInt().toString(),
                  _feedingUnit(context),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],

            const SizedBox(height: 24),

            EventDateTimeField(
              value: _selectedDate,
              onChanged: (date) => setState(() => _selectedDate = date),
            ),

            const SizedBox(height: 24),

            DialogActionButtons(
              onCancelPressed: () => Navigator.pop(context),
              onConfirmPressed: _inRange
                  ? () {
                      if (context.mounted) {
                        Navigator.pop(context, {
                          'subtype': _selectedSubtype,
                          // L'unité part avec le nombre : c'est elle qui dit ce
                          // que le chiffre veut dire.
                          'unit': _unit,
                          'quantity': _selectedQuantity,
                          'timestamp': _selectedDate,
                        });
                      }
                    }
                  : null,
              cancelLabel: context.l.cancelButton,
              confirmLabel: context.l.confirmButton,
            ),
          ],
        ),
      ),
    );
  }
}
