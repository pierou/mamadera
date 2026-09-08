import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';

/// Widget pour sélectionner le type de selle et les couleurs associées.
///
/// L'état de sélection est local au [StatefulWidget] : il ne survit pas à la
/// fermeture du dialog et ne fuit pas d'une ouverture à l'autre.
class WasteDialog extends StatefulWidget {
  const WasteDialog({super.key});

  @override
  State<WasteDialog> createState() => _WasteDialogState();
}

class _WasteDialogState extends State<WasteDialog> {
  WasteType _selectedType = WasteType.caca;
  PipiColor? _pipiColor;
  CacaColor? _cacaColor;

  /// Date and time of the diaper, defaulted to the moment the sheet opened.
  DateTime _selectedDate = DateTime.now();

  /// Retourne les données à retourner au parent (typed enums).
  Map<String, dynamic> _toResult() {
    return {
      'wasteType': _selectedType,
      'pipiColor': _pipiColor,
      'cacaColor': _cacaColor,
      'timestamp': _selectedDate,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              context.l.wasteDialogTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Sélection du type (chips radio)
            WasteDialogTypeChips(
              selectedType: _selectedType,
              onSelectedType: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 24),

            // Section couleur pipi (conditionnelle)
            if (_selectedType == WasteType.pipi || _selectedType == WasteType.lesDeux) ...[
              Text(context.l.pipiColorSectionTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              WasteDialogPipiColorChips(
                selectedColor: _pipiColor,
                onSelectedColor: (color) => setState(() => _pipiColor = color),
              ),
            ],
            if (_selectedType == WasteType.lesDeux) const SizedBox(height: 24),

            // Section couleur caca (conditionnelle)
            if (_selectedType == WasteType.caca || _selectedType == WasteType.lesDeux) ...[
              Text(context.l.cacaColorSectionTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              WasteDialogCacaColorChips(
                selectedColor: _cacaColor,
                onSelectedColor: (color) => setState(() => _cacaColor = color),
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
              onConfirmPressed: () {
                if (context.mounted) {
                  Navigator.pop(context, _toResult());
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

/// Widget pour les chips de sélection du type de selle.
class WasteDialogTypeChips extends StatelessWidget {
  const WasteDialogTypeChips({
    required this.selectedType,
    required this.onSelectedType,
    super.key,
  });

  final WasteType selectedType;
  final ValueChanged<WasteType> onSelectedType;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: WasteType.values.map((type) {
      final isSelected = type == selectedType;
      return _ChipRadio(
        label: switch (type) {
          WasteType.pipi => context.l.wasteTypePipi,
          WasteType.caca => context.l.wasteTypeCaca,
          WasteType.lesDeux => context.l.wasteTypeLesDeux,
        },
        isSelected: isSelected,
        onTap: () => onSelectedType(type),
      );
    }).toList());
  }
}

/// Widget pour les chips de couleur pipi.
class WasteDialogPipiColorChips extends StatelessWidget {
  const WasteDialogPipiColorChips({
    required this.selectedColor,
    required this.onSelectedColor,
    super.key,
  });

  final PipiColor? selectedColor;
  final ValueChanged<PipiColor?> onSelectedColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: pipiColors.map((c) {
      final isSelected = c == selectedColor;
      final cs = Theme.of(context).colorScheme;
      return FilterChip(
        label: Text(_resolvePipiLabel(context, c)),
        selected: isSelected,
        onSelected: (_) => onSelectedColor(isSelected ? null : c),
        backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.8),
        selectedColor: Color(c.colorHex).withValues(alpha: 0.3),
        checkmarkColor: cs.onPrimary,
        labelStyle: TextStyle(
          color: isSelected ? cs.onPrimary : null,
        ),
      );
    }).toList());
  }
}

/// Widget pour les chips de couleur caca.
class WasteDialogCacaColorChips extends StatelessWidget {
  const WasteDialogCacaColorChips({
    required this.selectedColor,
    required this.onSelectedColor,
    super.key,
  });

  final CacaColor? selectedColor;
  final ValueChanged<CacaColor?> onSelectedColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: cacaColors.map((c) {
      final isSelected = c == selectedColor;
      final cs = Theme.of(context).colorScheme;
      return FilterChip(
        label: Text(_resolveCacaLabel(context, c)),
        selected: isSelected,
        onSelected: (_) => onSelectedColor(isSelected ? null : c),
        backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.8),
        selectedColor: Color(c.colorHex).withValues(alpha: 0.3),
        checkmarkColor: cs.onPrimary,
        labelStyle: TextStyle(
          color: isSelected ? cs.onPrimary : null,
        ),
      );
    }).toList());
  }
}


class _ChipRadio extends StatelessWidget {
  const _ChipRadio({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '$label${isSelected ? ' (selected)' : ''}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.sante.withValues(alpha: 0.3) : Theme.of(context).cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppTheme.sante : Colors.transparent, width: 2),
          ),
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: textTheme.bodyMedium!.color),
          ),
        ),
      ),
    );
  }
}

/// Résout le label localisé pour un PipiColor via son labelKey.
String _resolvePipiLabel(BuildContext ctx, PipiColor c) {
  switch (c.labelKey) {
    case 'pipiColorIncolore':
      return ctx.l.pipiColorIncolore;
    case 'pipiColorJauneClair':
      return ctx.l.pipiColorJauneClair;
    case 'pipiColorJauneFonce':
      return ctx.l.pipiColorJauneFonce;
    case 'pipiColorRoseUrates':
      return ctx.l.pipiColorRoseUrates;
    default:
      return c.label;
  }
}

/// Résout le label localisé pour un CacaColor via son labelKey.
String _resolveCacaLabel(BuildContext ctx, CacaColor c) {
  switch (c.labelKey) {
    case 'cacaColorMeconium':
      return ctx.l.cacaColorMeconium;
    case 'cacaColorVertOlive':
      return ctx.l.cacaColorVertOlive;
    case 'cacaColorJauneMoutarde':
      return ctx.l.cacaColorJauneMoutarde;
    case 'cacaColorJauneClair':
      return ctx.l.cacaColorJauneClair;
    default:
      return c.label;
  }
}
