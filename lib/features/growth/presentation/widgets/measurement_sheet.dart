import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../home/presentation/widgets/quantity_picker_inline.dart';
import '../../domain/entities/measure_kind.dart';
import '../providers/measurement_providers.dart';
import 'measure_kind_accent.dart';

/// Feuille de saisie d'une mesure de croissance (poids, taille, température).
///
/// La valeur de départ est 0 — toujours hors bornes — pour que le parent
/// choisisse un nombre : l'état « hors plage » (erreur inline + enregistrement
/// désactivé) fait partie du parcours normal, pas d'un cas d'erreur. Le
/// slider ramène la valeur dans les bornes dès le premier glissement.
///
/// Sauvegarde en [double] : `null` = annulée, sinon la valeur enregistrée
/// (l'appelant affiche la confirmation, comme les feuilles d'accueil).
class MeasurementSheet extends ConsumerStatefulWidget {
  const MeasurementSheet({required this.kind, super.key});

  final MeasureKind kind;

  @override
  ConsumerState<MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends ConsumerState<MeasurementSheet> {
  /// Valeur courante, en unité de base (g, cm, °C).
  double _value = 0;

  /// Date de la mesure, modifiable comme sur les autres fiches.
  late final DateTime _selectedDate;

  late final TextEditingController _noteController;

  bool get _inRange => widget.kind.contains(_value);

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repository = await ref.read(measurementRepositoryProvider.future);
    if (!mounted) return;
    // `null` = lignes sans profil (suivi avant création du profil).
    final babyId = ref.read(activeBabyProvider).value?.id;
    final note = _noteController.text.trim();
    await repository.add(
      babyId: babyId,
      kind: widget.kind,
      value: _value,
      recordedAt: _selectedDate,
      notes: note.isEmpty ? null : note,
    );
    if (!mounted) return;
    await ref.read(measurementNotifierProvider.notifier).refresh();
    if (!mounted) return;
    Navigator.of(context).pop(_value);
  }

  /// Titre de la feuille, par grande (pas de clé dérivée : switch explicite).
  String _titleFor(BuildContext context) {
    return switch (widget.kind) {
      MeasureKind.poids => context.l.growthSheetTitleWeight,
      MeasureKind.taille => context.l.growthSheetTitleHeight,
      MeasureKind.temperature => context.l.growthSheetTitleTemperature,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final theme = Theme.of(context);
    final kind = widget.kind;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingXl,
        AppTheme.spacingXl,
        AppTheme.spacingXl,
        MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacingXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleFor(context),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          QuantityPickerInline(
            unit: kind.displayUnit,
            min: kind.min,
            max: kind.max,
            divisions: kind.divisions,
            decimals: kind.decimals,
            // Stepper +/- d'un pas du slider : c'est le seul instrument de
            // précision qui reste quand la plage compte des milliers de crans.
            step: kind.step,
            value: _value,
            onValueChanged: (value) => setState(() => _value = value),
            accentColor: kind.accent,
          ),
          if (!_inRange)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingMd),
              child: Text(
                l.growthValueOutOfRange(
                  kind.formatBound(kind.min),
                  kind.formatBound(kind.max),
                  kind.displayUnit,
                ),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: AppTheme.spacingLg),
          EventDateTimeField(
            value: _selectedDate,
            onChanged: (value) => setState(() => _selectedDate = value),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: l.growthSheetNoteField,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
            ),
            maxLines: null,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          DialogActionButtons(
            onCancelPressed: () => Navigator.of(context).pop(),
            onConfirmPressed: _inRange ? _save : null,
            cancelLabel: l.cancel,
            confirmLabel: l.growthSheetSave,
          ),
        ],
      ),
    );
  }
}
