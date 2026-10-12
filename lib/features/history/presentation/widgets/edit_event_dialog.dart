import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/unit_localization.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/event_date_time_field.dart';
import '../../../../shared/domain/entities/quantity_unit.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';
import '../../../../shared/domain/entities/tracking_icons.dart';
import '../../../../shared/utils/health_label_resolver.dart';
import '../../../../shared/utils/stool_texture_label_resolver.dart';
import '../../../home/presentation/widgets/quantity_picker_inline.dart';

part 'edit_event_dialog.freezed.dart';

/// Résultat retourné par le formulaire d'édition (sealed class).
@freezed
sealed class EditResult with _$EditResult {
  const factory EditResult.update({
    DateTime? timestamp,
    double? duration,
    double? quantity,

    /// Unité du nombre porté, telle qu'éditée (toggle ml/min au sein, ou
    /// changement de sous-type passant la ligne en grammes).
    QuantityUnit? unit,
    String? notes,
    FeedingSubtype? subtype,
    WasteType? wasteType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
    StoolTexture? stoolTexture,
    HealthSubtype? healthSubtype,
  }) = UpdateResult;

  const factory EditResult.delete() = DeleteResult;
}

/// Bottom sheet pour éditer les champs modifiables d'un événement.
class EditEventDialog extends ConsumerStatefulWidget {
  const EditEventDialog(this.event, {super.key});

  /// Événement typé à modifier.
  final TrackingEvent event;

  @override
  ConsumerState<EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends ConsumerState<EditEventDialog> {
  late DateTime _selectedDate;
  late TextEditingController _notesController;
  double? _duration;
  double? _quantity;

  // Sous-type d'alimentation (natural/artificial/solid) pour feedings
  FeedingSubtype _subtype = FeedingSubtype.natural;

  /// Unité de la quantité en cours d'édition, lue de la ligne à l'ouverture.
  QuantityUnit _unit = QuantityUnit.ml;

  /// La quantité est remise à 0 quand l'unité change, et le dialog le dit.
  bool _unitResetNotice = false;

  /// Nombre saisi hors des bornes ; `null` = dans la plage.
  double? _outOfRange;

  // Pour les événements caca : type de selle et couleurs (typed via enums)
  WasteType? _wasteType;
  PipiColor? _pipiColor;
  CacaColor? _cacaColor;
  StoolTexture? _stoolTexture;

  // Sous-type de soin pour les événements santé (indépendant des notes)
  HealthSubtype? _healthSubtype;

  /// Version normalisée en minuscule pour les comparaisons.
  String get _normalizedType {
    return widget.event.map(
      (e) => 'unknown',
      feeding: (_) => 'miam',
      sleep: (_) => 'dodo',
      diaper: (e) {
        if (e.wasteType == WasteType.pipi) return 'pipi';
        return 'caca';
      },
      health: (_) => 'sante',
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.event.timestamp;
    _subtype = FeedingSubtype.natural;
    _duration = null;
    _quantity = null;
    _notesController = TextEditingController(text: '');
    _wasteType = null;
    _pipiColor = null;
    _cacaColor = null;
    _stoolTexture = null;
    _healthSubtype = null;
    _initEventFields();
  }

  /// Initialise les champs spécifiques au type d'événement.
  void _initEventFields() {
    widget.event.map(
      (e) {},
      feeding: (e) {
        _subtype = e.subtype;
        _unit = e.unit;
        _quantity = e.quantity;
        _notesController.text = e.notes ?? '';
      },
      sleep: (e) {
        _duration = e.duration;
        _quantity = e.quantity;
      },
      diaper: (e) {
        _wasteType = e.wasteType;
        _pipiColor = e.pipiColor;
        _cacaColor = e.cacaColor;
        _stoolTexture = e.stoolTexture;
        _notesController.text = e.notes ?? '';
      },
      health: (e) {
        _healthSubtype = e.subtype;
        _notesController.text = e.notes ?? '';
      },
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final result = EditResult.update(
      timestamp: _selectedDate,
      duration: _duration,
      quantity: _quantity,
      // L'unité courante part avec le nombre : passer de `natural`+`min` à
      // `solid` rend `g`, rester au sein garde le choix du parent.
      unit: _unit,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      subtype: (_normalizedType == 'miam') ? _subtype : null,
      wasteType: _wasteType,
      pipiColor: _pipiColor,
      cacaColor: _cacaColor,
      stoolTexture: _stoolTexture,
      healthSubtype: _healthSubtype,
    );
    Navigator.pop(context, result);
  }

  /// Ouvre un dialogue de confirmation avant suppression.
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: _buildDeleteDialogWithDialogContext,
      useRootNavigator: true,
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const EditResult.delete());
    }
  }

  Widget _buildDeleteDialogWithDialogContext(BuildContext dialogContext) {
    return AlertDialog(
      title: Text(dialogContext.l.deleteDialogTitle),
      content: Text(dialogContext.l.deleteDialogContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.l.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          child: Text(dialogContext.l.deleteButton),
        ),
      ],
    );
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
            _buildTitle(),
            _buildDateSection(),
            const SizedBox(height: 20),
            if (_normalizedType == 'dodo') ..._buildDurationSection(),
            if (_normalizedType == 'miam') ..._buildQuantitySection(),
            if (_normalizedType == 'miam') ..._buildSubtypeSelectorSection(),
            if (_normalizedType == 'caca' || _normalizedType == 'pipi')
              ..._buildWasteSections(),
            if (_normalizedType != 'sante' && _normalizedType != 'dodo')
              ..._buildNotesSection(),
            if (_normalizedType == 'sante') ..._buildHealthSubtypeSection(),
            ..._buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      context.l.editDialogTitle,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDateSection() {
    return EventDateTimeField(
      value: _selectedDate,
      onChanged: (date) => setState(() => _selectedDate = date),
    );
  }

  List<Widget> _buildDurationSection() {
    return [
      _buildSectionTitle(context.l.editDurationSectionTitle),
      QuantityPickerInline(
        unit: context.l.minuteSuffix,
        min: 0,
        max: 480,
        divisions: 96,
        // Stepper aligné sur le pas du slider : 96 crans sur 480 min.
        step: 5,
        // Paire B2 : 96 crans au pas de 5 — un seul slider ne suffit plus.
        sliderPair: const (coarseStep: 30, fineSpan: 30, fineStep: 5),
        value: _quantity ?? 0.0,
        onValueChanged: (double value) {
          setState(() {
            _quantity = value;
            _duration = value;
          });
        },
      ),
    ];
  }

  List<Widget> _buildQuantitySection() {
    return [
      const SizedBox(height: 20),
      _buildSectionTitle(context.l.editQuantitySectionTitle),
      // Le sein est le seul sous-type à deux unités : téter se compte en
      // minutes, tirer se compte en millilitres, et la même mère fait les
      // deux le même jour. Les autres sous-types restent figés.
      if (_subtype == FeedingSubtype.natural) ...[
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
        const SizedBox(height: 12),
      ],
      // Le message de remise à 0 sort du bloc `natural` : un re-typage
      // biberon → solide remet aussi la quantité à 0 (le nombre ne survit pas
      // au changement d'unité), et une remise à 0 silencieuse est le défaut
      // que v1.2.1 existe à supprimer.
      if (_unitResetNotice) ...[
        const SizedBox(height: 8),
        Text(
          context.l.feedingUnitReset,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
      ],
      QuantityPickerInline(
        unit: quantityUnitLabel(context, _unit),
        min: _pickerSpec.min,
        max: _pickerSpec.max,
        divisions: _pickerSpec.divisions,
        // Stepper aligné sur le pas du slider pour l'unité courante.
        step: _pickerSpec.step,
        sliderPair: _pickerSpec.sliderPair,
        value: _quantity ?? 0.0,
        onValueChanged: (double value) {
          setState(() {
            _quantity = value;
            _outOfRange = null;
          });
        },
        // Hors plage : le nombre du parent reste affiché, l'erreur apparaît,
        // Enregistrer se désactive. Jamais de `clamp` (BACKLOG B5).
        onValueOutOfRange: (value) => setState(() {
          _quantity = value;
          _outOfRange = value;
        }),
      ),
      if (_outOfRange != null) ...[
        const SizedBox(height: 8),
        Text(
          context.l.feedingValueOutOfRange(
            _pickerSpec.min.toInt().toString(),
            _pickerSpec.max.toInt().toString(),
            quantityUnitLabel(context, _unit),
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ],
    ];
  }

  /// Bornes et pas du picker, selon l'unité — les mêmes que la saisie
  /// d'un nouvel événement (ml 0–300 par 10, min 0–120 par 1, g 0–1000
  /// par 5) : éditer une valeur ne doit pas ouvrir une plage différente.
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

  /// Unité d'un sous-type, figée hors `natural`.
  static QuantityUnit _unitFor(FeedingSubtype subtype) => switch (subtype) {
        FeedingSubtype.natural => QuantityUnit.min,
        FeedingSubtype.artificial => QuantityUnit.ml,
        FeedingSubtype.solid => QuantityUnit.g,
      };

  /// Choix du sous-type : l'unité suit, et le nombre ne survit pas à un
  /// changement d'unité — 20 ml n'est pas 20 minutes.
  void _selectSubtype(FeedingSubtype subtype) {
    setState(() {
      _subtype = subtype;
      final nextUnit = _unitFor(subtype);
      if (nextUnit != _unit) {
        _unit = nextUnit;
        _quantity = 0;
        _unitResetNotice = true;
      }
      _outOfRange = null;
    });
  }

  /// Choix ml/min au sein : même règle, aucun nombre ne change d'unité en
  /// douceur.
  void _selectUnit(QuantityUnit unit) {
    if (unit == _unit) return;
    setState(() {
      _unit = unit;
      _quantity = 0;
      _unitResetNotice = true;
      _outOfRange = null;
    });
  }

  List<Widget> _buildSubtypeSelectorSection() {
    return [
      const SizedBox(height: 20),
      _buildSectionTitle(context.l.feedingSubtypeLabel),
      Row(
        children: FeedingSubtype.values.map((subtype) {
          final isSelected = _subtype == subtype;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(subtype.icon, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _getSubtypeLabel(subtype),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => _selectSubtype(subtype),
              ),
            ),
          );
        }).toList(),
      ),
    ];
  }

  String _getSubtypeLabel(FeedingSubtype subtype) {
    return switch (subtype) {
      FeedingSubtype.natural => context.l.feedingSubtypeNatural,
      FeedingSubtype.artificial => context.l.feedingSubtypeArtificial,
      FeedingSubtype.solid => context.l.feedingSolid,
    };
  }

  List<Widget> _buildWasteSections() {
    final sections = <Widget>[];

    if (_normalizedType == 'caca') {
      sections.addAll([
        _buildSectionTitle(context.l.editTypeSectionTitle),
        Row(
          children: [
            for (final type in WasteType.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(_wasteTypeLabel(type)),
                    selected: _wasteType == type,
                    onSelected: (_) => setState(() => _wasteType = type),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (_normalizedType == 'pipi' ||
        _wasteType == WasteType.pipi ||
        _wasteType == WasteType.lesDeux) {
      sections.addAll(_buildPipiColors());
    }

    if (_wasteType == WasteType.caca || _wasteType == WasteType.lesDeux) {
      sections.addAll([
        // La consistance ne s'affiche que là où elle veut dire quelque chose :
        // les 5 crans sous « caca » ajoutent un scroll en bas d'un bottom sheet
        // déjà dense, on ne les montre donc pas pour un simple pipi.
        ..._buildCacaColors(),
        ..._buildStoolTextures(),
      ]);
    }

    return sections;
  }

  List<Widget> _buildStoolTextures() {
    return [
      _buildSectionTitle(context.l.stoolTextureSectionTitle),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: stoolTextures
            .map((t) => FilterChip(
                  label: Text(resolveStoolTextureLabel(context, t)),
                  selected: _stoolTexture == t,
                  onSelected: (_) => setState(
                      () => _stoolTexture = _stoolTexture == t ? null : t),
                ))
            .toList(),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildPipiColors() {
    return [
      _buildSectionTitle(context.l.editPipiColorSectionTitle),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: pipiColors
            .map((c) => FilterChip(
                  label: Text(_resolvePipiLabel(context, c)),
                  selected: _pipiColor == c,
                  onSelected: (_) =>
                      setState(() => _pipiColor = _pipiColor == c ? null : c),
                ))
            .toList(),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildCacaColors() {
    return [
      _buildSectionTitle(context.l.editCacaColorSectionTitle),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: cacaColors
            .map((c) => FilterChip(
                  label: Text(_resolveCacaLabel(context, c)),
                  selected: _cacaColor == c,
                  onSelected: (_) =>
                      setState(() => _cacaColor = _cacaColor == c ? null : c),
                ))
            .toList(),
      ),
    ];
  }

  List<Widget> _buildNotesSection() {
    return [
      const SizedBox(height: 20),
      _buildSectionTitle(context.l.editNotesLabel),
      TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: context.l.editNotesHint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    ];
  }

  List<Widget> _buildHealthSubtypeSection() {
    return [
      const SizedBox(height: 20),
      _buildSectionTitle(context.l.healthSubtypeDialogTitle),
      ..._buildHealthTiles(),
    ];
  }

  List<ListTile> _buildHealthTiles() {
    return HealthSubtype.values.map((subtype) {
      final isSelected = _healthSubtype == subtype;
      return ListTile(
        leading: Icon(HealthIcons.fromValue(subtype.value),
            color: isSelected ? AppTheme.sante : null),
        title: Text(resolveHealthLabel(context, subtype)),
        trailing: isSelected
            ? Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary)
            : null,
        tileColor: isSelected ? AppTheme.sante.withValues(alpha: 0.15) : null,
        onTap: () => setState(() => _healthSubtype = subtype),
      );
    }).toList();
  }

  List<Widget> _buildActionButtons() {
    return [
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          // Hors plage : on ne sauvegarde pas, on n'efface pas non plus —
          // le nombre reste à l'écran avec son message d'erreur.
          onPressed: _outOfRange == null ? _submit : null,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: Text(context.l.saveButton),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l.closeButton),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(context.l.deleteButton),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
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

  /// Retourne le label d'un WasteType via l'enum.
  String _wasteTypeLabel(WasteType type) {
    switch (type) {
      case WasteType.pipi:
        return context.l.wasteTypePipi;

      case WasteType.caca:
        return context.l.wasteTypeCaca;
      case WasteType.lesDeux:
        return context.l.wasteTypeLesDeux;
    }
  }
}
