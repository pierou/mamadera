import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_icons.dart';
import 'quantity_picker_inline.dart';

/// A dialog for tracking feeding events with subtype selection and quantity.
///
/// Contains:
/// - Feeding subtype chip selector (natural/artificial) at the top
/// - Quantity picker (ml) below
/// - Confirm button that returns (feedingSubtype, quantity)
class FeedingTrackingDialog extends ConsumerStatefulWidget {
  const FeedingTrackingDialog({super.key});

  @override
  ConsumerState<FeedingTrackingDialog> createState() => _FeedingTrackingDialogState();
}

class _FeedingTrackingDialogState extends ConsumerState<FeedingTrackingDialog> {
  late FeedingSubtype _selectedSubtype;
  double _selectedQuantity = 0;

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
              unit: 'ml',
              min: 0,
              max: 300,
              divisions: 30,
              value: _selectedQuantity,
              onValueChanged: _onQuantityChanged,
            ),

            const SizedBox(height: 24),

            DialogActionButtons(
              onCancelPressed: () => Navigator.pop(context),
              onConfirmPressed: () {
                if (context.mounted) {
                  Navigator.pop(context, {
                    'subtype': _selectedSubtype,
                    'quantity': _selectedQuantity,
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
