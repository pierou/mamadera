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

/// Sheet for entering a growth measurement (weight, height, temperature).
class MeasurementSheet extends ConsumerStatefulWidget {
  const MeasurementSheet({
    required this.kind,
    super.key,
  });

  final MeasureKind kind;

  /// Opens the sheet and returns the entered value (null if cancelled).
  static Future<double?> show(
    BuildContext context, {
    required MeasureKind kind,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MeasurementSheet(kind: kind),
    );
  }

  @override
  ConsumerState<MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends ConsumerState<MeasurementSheet> {
  late double _value;
  bool _inRange = true;
  DateTime _selectedDate = DateTime.now();
  late TextEditingController _noteController;

  /// Libellé d'appoint « dernière : 36,8 °C », résolu en asynchrone — `null`
  /// tant que le chargement n'est pas arrivé, auquel cas le rendu retombe sur
  /// la référence du type. Résolu **hors de `initState`** : `context.l` n'y
  /// est pas encore sûr, et l'asynchrone ne laisse jamais un rendu
  /// intermédiaire pré-remplir le champ.
  String? _lastHint;

  /// Le parent a-t-il saisi un chiffre ? Le bouton de sauvegarde n'ouvre pas
  /// avant : en afficher la valeur de départ comme une mesure prise, ce
  /// serait l'inventer.
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _value = widget.kind.defaultValue;
    _noteController = TextEditingController();
    _loadLastValue();
  }

  /// Libellé d'appoint : la dernière mesure du même type si elle existe,
  /// sinon la valeur de référence du type (« 37 °C »).
  String get _hintLabel =>
      _lastHint ??
      widget.kind
          .format(widget.kind.defaultValue, localeName: context.l.localeName);

  /// Dernière mesure du même type, si elle existe : « dernière : 36,8 °C ».
  /// En erreur ou sans valeur (chiffre illisible), on garde la référence du
  /// type — l'appoint est un confort, jamais un bloqueur.
  ///
  /// Elle sert aussi de **point de départ du curseur et des boutons ±** (défaut
  /// v1.2.1 signalé sur l'appareil) : l'en-tête affiche « dernière : 36,8 °C »
  /// dès l'ouverture, et le premier contact avec le curseur ou un ± renvoyait
  /// 37,0 — la référence du type, c'est-à-dire un nombre que personne n'a mesuré.
  /// Ce qui est visé doit être à l'endroit visé. Le champ texte reste vide et la
  /// sauvegarde désactivée : une **position** de curseur n'est pas une saisie.
  Future<void> _loadLastValue() async {
    try {
      final repository = await ref.read(measurementRepositoryProvider.future);
      final babyId = ref.read(activeBabyProvider).value?.id;
      final last = await repository.latestOfKind(babyId, widget.kind);
      final lastValue = last?.value;
      if (!mounted || lastValue == null) return;
      setState(() {
        _lastHint = context.l.growthSheetLastValueHint(
          widget.kind.format(lastValue, localeName: context.l.localeName),
        );
        // Jamais après une saisie du parent : la lecture arrive en asynchrone et
        // écraserait le chiffre qu'il est en train de taper.
        if (!_hasInput && widget.kind.contains(lastValue)) {
          _value = lastValue;
        }
      });
    } catch (_) {
      // La feuille reste utilisable sans l'appoint.
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_inRange) return;
    final repository = await ref.read(measurementRepositoryProvider.future);
    final babyId = ref.read(activeBabyProvider).value?.id;
    await repository.add(
      babyId: babyId,
      kind: widget.kind,
      value: _value,
      recordedAt: _selectedDate,
      notes: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    // Relecture ici, avant de fermer : la rangée d'accueil et l'écran Croissance
    // watchent `measurementNotifierProvider`, qui ne se relit ni tout seul ni au
    // retour d'une autre page (défaut v1.2.1 : le parent qui enregistre 4,2 kg
    // restait affiché sur 3,9 kg jusqu'à changer de bébé).
    await ref.read(measurementNotifierProvider.notifier).refresh();
    if (!mounted) return;
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    // Les bornes de l'en-tête affichent les unités, pas des chiffres bruts :
    // « 200–20000 g » se lit « entre deux centaines et vingt kilos ».
    final rangeLabel =
        '${widget.kind.min.round()}–${widget.kind.max.round()} ${widget.kind.displayUnit}';
    final title = switch (widget.kind) {
      MeasureKind.poids => l.growthSheetTitleWeight,
      MeasureKind.taille => l.growthSheetTitleHeight,
      MeasureKind.temperature => l.growthSheetTitleTemperature,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        top: AppTheme.spacingMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingMd,
      ),
      child: SingleChildScrollView(
        // Si la feuille dépasse l'écran (petit téléphone, clavier ouvert),
        // elle défile au lieu de couper : le bouton d'enregistrement doit
        // rester atteignable à toute taille.
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
            const SizedBox(height: 4),
            Text(
              rangeLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            QuantityPickerInline(
              unit: widget.kind.displayUnit,
              min: widget.kind.min,
              max: widget.kind.max,
              divisions: widget.kind.divisions,
              step: widget.kind.step,
              decimals: widget.kind.decimals,
              value: _value,
              accentColor: widget.kind.accent,
              hintLabel: _hintLabel,
              onValueChanged: (double value) {
                setState(() {
                  _value = value;
                  _inRange = true;
                  _hasInput = true;
                });
              },
              onValueOutOfRange: (double value) {
                setState(() {
                  _value = value;
                  _inRange = false;
                  _hasInput = true;
                });
              },
            ),
            if (!_inRange) ...[
              const SizedBox(height: 8),
              Text(
                l.growthValueOutOfRange(
                  widget.kind.formatBound(widget.kind.min),
                  widget.kind.formatBound(widget.kind.max),
                  widget.kind.displayUnit,
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
            DialogCancelButton(
              label: l.cancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            DialogConfirmButton(
              label: l.growthSheetSave,
              onPressed: (_inRange && _hasInput) ? _save : null,
              showIcon: true,
            ),
          ],
        ),
      ),
    );
  }
}
