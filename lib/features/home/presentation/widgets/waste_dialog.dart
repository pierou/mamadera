import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';

/// State interne du dialog de sélection de selle.
class _WasteDialogState {
  const _WasteDialogState({
    this.selectedType = WasteType.caca,
    this.pipiColor,
    this.cacaColor,
  });

  final WasteType selectedType;
  final PipiColor? pipiColor;
  final CacaColor? cacaColor;

  _WasteDialogState copyWith({
    WasteType? selectedType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
  }) {
    return _WasteDialogState(
      selectedType: selectedType ?? this.selectedType,
      pipiColor: pipiColor ?? this.pipiColor,
      cacaColor: cacaColor ?? this.cacaColor,
    );
  }

  /// Retourne la valeur DB formatée pour wasteType.
  String? get wasteTypeValue => selectedType.dbValue;

  /// Retourne la valeur DB formatée pour color (pipe-délimité si lesDeux).
  String? get colorDbValue {
    switch (selectedType) {
      case WasteType.pipi:
        return pipiColor?.value;
      case WasteType.caca:
        return cacaColor?.value;
      case WasteType.lesDeux:
        final p = pipiColor?.value ?? '';
        final c = cacaColor?.value ?? '';
        if (p.isNotEmpty && c.isNotEmpty) {
          return '$p|$c';
        }
        return p.isEmpty ? c : p;
    }
  }

  /// Retourne les données à retourner au parent (typed enums).
  Map<String, dynamic> toResult() {
    return {
      'wasteType': selectedType,
      'pipiColor': pipiColor,
      'cacaColor': cacaColor,
    };
  }
}

/// Provider pour gérer l'état du dialog de selle.
final _wasteDialogStateProvider = NotifierProvider<_WasteDialogNotifier, _WasteDialogState>(
  _WasteDialogNotifier.new,
);

class _WasteDialogNotifier extends Notifier<_WasteDialogState> {
  @override
  _WasteDialogState build() => const _WasteDialogState();

  void setSelectedType(WasteType type) {
    state = state.copyWith(selectedType: type);
  }

  void setPipiColor(PipiColor? color) {
    state = state.copyWith(pipiColor: color);
  }

  void setCacaColor(CacaColor? color) {
    state = state.copyWith(cacaColor: color);
  }

  void reset() {
    state = const _WasteDialogState();
  }
}

/// Widget pour sélectionner le type de selle et les couleurs associées.
class WasteDialog extends ConsumerWidget {
  const WasteDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_wasteDialogStateProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            const Text('Type de selle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),

            // Sélection du type (chips radio) — utilise l'enum WasteType au lieu de strings
            _buildTypeChips(ref, state.selectedType),
            const SizedBox(height: 24),

            // Section couleur pipi (conditionnelle, typée via enum)
            if (state.selectedType == WasteType.pipi || state.selectedType == WasteType.lesDeux) ...[
              const Text('Couleur du pipi', style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 8),
              _buildPipiColorChips(ref, state.pipiColor),
            ],

            if (state.selectedType == WasteType.lesDeux) const SizedBox(height: 24),

            // Section couleur caca (conditionnelle, typée via enum)
            if (state.selectedType == WasteType.caca || state.selectedType == WasteType.lesDeux) ...[
              const Text('Couleur du caca', style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 8),
              _buildCacaColorChips(ref, state.cacaColor),
            ],

            const SizedBox(height: 24),

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _onSubmit(context, ref),
                icon: const Icon(Icons.check, color: Colors.black),
                label: const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildTypeChips(WidgetRef ref, WasteType selectedType) {
    return Wrap(spacing: 8, runSpacing: 8, children: WasteType.values.map((type) {
      final isSelected = type == selectedType;
      return _ChipRadio(
        label: switch (type) {
          WasteType.pipi => '🟡 Pipi',
          WasteType.caca => '🟤 Caca',
          WasteType.lesDeux => '🟡🟤 Les deux',
        },
        isSelected: isSelected,
        onTap: () => ref.read(_wasteDialogStateProvider.notifier).setSelectedType(type),
      );
    }).toList());
  }

  Widget _buildPipiColorChips(WidgetRef ref, PipiColor? selectedColor) {
    return Wrap(spacing: 8, runSpacing: 8, children: PipiColor.values.map((c) {
      final isSelected = c == selectedColor;
      return FilterChip(
        label: Text(c.label),
        selected: isSelected,
        onSelected: (_) => ref.read(_wasteDialogStateProvider.notifier).setPipiColor(isSelected ? null : c),
        backgroundColor: AppTheme.background.withValues(alpha: 0.8),
        selectedColor: Color(c.colorHex).withValues(alpha: 0.3),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
      );
    }).toList());
  }

  Widget _buildCacaColorChips(WidgetRef ref, CacaColor? selectedColor) {
    return Wrap(spacing: 8, runSpacing: 8, children: CacaColor.values.map((c) {
      final isSelected = c == selectedColor;
      return FilterChip(
        label: Text(c.label),
        selected: isSelected,
        onSelected: (_) => ref.read(_wasteDialogStateProvider.notifier).setCacaColor(isSelected ? null : c),
        backgroundColor: AppTheme.background.withValues(alpha: 0.8),
        selectedColor: Color(c.colorHex).withValues(alpha: 0.3),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
      );
    }).toList());
  }

  void _onSubmit(BuildContext context, WidgetRef ref) {
    final state = ref.read(_wasteDialogStateProvider);
    Navigator.pop(context, state.toResult());
  }
}

class _ChipRadio extends StatelessWidget {
  const _ChipRadio({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.sante.withValues(alpha: 0.3) : AppTheme.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.sante : Colors.transparent, width: 2),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
      ),
    );
  }
}
