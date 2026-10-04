import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_icons.dart';
import 'quantity_picker_inline.dart';

/// A dialog for tracking feeding events with subtype selection and quantity.
///
/// Contains:
/// - Feeding subtype chip selector (natural/artificial/solid) at the top
/// - Quantity picker whose unit follows the selected subtype (min/ml/g) below
/// - Date and time of the feed (defaults to now)
/// - Confirm button that returns (feedingSubtype, quantity, timestamp)
class FeedingTrackingDialog extends ConsumerStatefulWidget {
  const FeedingTrackingDialog({super.key});

  @override
  ConsumerState<FeedingTrackingDialog> createState() => _FeedingTrackingDialogState();
}

class _FeedingTrackingDialogState extends ConsumerState<FeedingTrackingDialog> {
  late FeedingSubtype _selectedSubtype;
  double _selectedQuantity = 0;

  /// Date and time of the feed. Defaulted once at open time: the dialog is
  /// rebuilt on every slider tick, so a plain field initialiser keeps the
  /// displayed "now" stable while the parent is choosing.
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedSubtype = FeedingSubtype.natural; // Default to breast milk
  }

  void _onQuantityChanged(double quantity) {
    setState(() {
      _selectedQuantity = quantity;
    });
  }

  bool get _isSolid => _selectedSubtype == FeedingSubtype.solid;

  /// L'unité du picker suit le sous-type sélectionné : minutes au sein,
  /// millilitres (sein et biberon), grammes pour les solides. Afficher « 40 ml »
  /// alors que « Solide » est sélectionné, ce serait un chiffre de santé
  /// faux — exactement ce que l'app ne doit jamais afficher.
  String _feedingUnit(BuildContext context) => switch (_selectedSubtype) {
        // Le sein se saisit en ml comme le biberon — c'est ce que la colonne
        // `quantity` a toujours stocké pour `miam` (`FeedingEvent` n'a pas de
        // champ durée). Inventer des minutes ici re-étiquetterait des
        // enregistrements existants de lait tiré en durée de tétée.
        FeedingSubtype.natural => 'ml',
        FeedingSubtype.artificial => 'ml',
        FeedingSubtype.solid => context.l.gramSuffix,
      };

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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Feeding subtype selector
            Text(
              context.l.feedingSubtypeLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    onSelected: (_) => setState(() => _selectedSubtype = FeedingSubtype.natural),
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
                    onSelected: (_) => setState(() => _selectedSubtype = FeedingSubtype.artificial),
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
                    onSelected: (_) => setState(() => _selectedSubtype = FeedingSubtype.solid),
                    selectedColor: AppTheme.miam.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quantity section
            Text(
              context.l.feedingQuantityLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            QuantityPickerInline(
              unit: _feedingUnit(context),
              min: 0,
              // Les solides se pèsent en grammes sur une plus large plage.
              max: _isSolid ? 1000 : 300,
              divisions: _isSolid ? 200 : 30,
              // Stepper aligné sur le pas du slider : 200 crans sur 1000 g,
              // 30 crans sur 300 (min ou ml).
              step: _isSolid ? 5 : 10,
              value: _selectedQuantity,
              onValueChanged: _onQuantityChanged,
            ),

            const SizedBox(height: 24),

            EventDateTimeField(
              value: _selectedDate,
              onChanged: (date) => setState(() => _selectedDate = date),
            ),

            const SizedBox(height: 24),

            DialogActionButtons(
              onCancelPressed: () => Navigator.pop(context),
              onConfirmPressed: () {
                if (context.mounted) {
                  Navigator.pop(context, {
                    'subtype': _selectedSubtype,
                    'quantity': _selectedQuantity,
                    'timestamp': _selectedDate,
                  });
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
