import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/l10n/date_localization.dart';
import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';

part 'edit_event_dialog.freezed.dart';

/// Résultat retourné par le formulaire d'édition (sealed class).
@freezed
sealed class EditResult with _$EditResult {
  const factory EditResult.update({
    DateTime? timestamp,
    double? duration,
    String? notes,
    WasteType? wasteType,
    PipiColor? pipiColor,
    CacaColor? cacaColor,
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

  // Pour les événements caca : type de selle et couleurs (typed via enums)
  WasteType? _wasteType;
  PipiColor? _pipiColor;
  CacaColor? _cacaColor;

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
    _duration = null;
    _notesController = TextEditingController(text: '');
    _wasteType = null;
    _pipiColor = null;
    _cacaColor = null;
    _initEventFields();
  }

  /// Initialise les champs spécifiques au type d'événement.
  void _initEventFields() {
    widget.event.map(
      (e) {},
      feeding: (e) {
        _duration = e.duration;
        _notesController.text = e.notes ?? '';
      },
      sleep: (e) {
        _duration = e.duration;
      },
      diaper: (e) {
        _wasteType = e.wasteType;
        _pipiColor = e.pipiColor;
        _cacaColor = e.cacaColor;
        _notesController.text = e.notes ?? '';
      },
      health: (e) {
        _notesController.text = e.subtype.value;
      },
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }


  Future<void> _pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
        lastDate: DateTime.now());
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) {
      _updateToDateOnly(date);
      return;
    }

    _applyDateTime(date, time);
  }

  void _applyDateTime(DateTime date, TimeOfDay time) {
    setState(() {
      _selectedDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _updateToDateOnly(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day,
          _selectedDate.hour, _selectedDate.minute);
    });
  }

  void _submit() {
    final result = EditResult.update(
      timestamp: _selectedDate,
      duration: _duration,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      wasteType: _wasteType,
      pipiColor: _pipiColor,
      cacaColor: _cacaColor,
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
            ..._buildDateSection(),
            if (_normalizedType == 'dodo') ..._buildDurationSection(),
            if (_normalizedType == 'caca' || _normalizedType == 'pipi') ..._buildWasteSections(),
            if (_normalizedType != 'sante' && _normalizedType != 'dodo') ..._buildNotesSection(),
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
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  List<Widget> _buildDateSection() {
    return [
      _buildSectionTitle(context.l.editDateSectionTitle),
      _buildDateInlineAction(),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildDateInlineAction() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
        child: _buildDateInlineRow(),
      ),
    );
  }

  Widget _buildDateInlineRow() {
    return Row(
      children: [
        Icon(Icons.calendar_today,
            size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(_formatDateTime(_selectedDate)),
        const Spacer(),
        Icon(Icons.edit_outlined,
            size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }

  List<Widget> _buildDurationSection() {
    return [
      _buildSectionTitle(context.l.editDurationSectionTitle),
      TextFormField(
        initialValue: _duration != null ? '${_duration!.toInt()}' : '',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: context.l.minutesHintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          suffixText: context.l.minuteSuffix,
        ),
        onChanged: (value) {
          _duration = value.isEmpty ? null : double.tryParse(value);
        },
      ),
      const SizedBox(height: 20),
    ];
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
      sections.addAll(_buildCacaColors());
    }

    return sections;
  }

  List<Widget> _buildPipiColors() {
    return [
      _buildSectionTitle(context.l.editPipiColorSectionTitle),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: pipiColors.map((c) => FilterChip(
          label: Text(_resolvePipiLabel(context, c)),
          selected: _pipiColor == c,
          onSelected: (_) => setState(() => _pipiColor = _pipiColor == c ? null : c),
        )).toList(),
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
        children: cacaColors.map((c) => FilterChip(
          label: Text(_resolveCacaLabel(context, c)),
          selected: _cacaColor == c,
          onSelected: (_) => setState(() => _cacaColor = _cacaColor == c ? null : c),
        )).toList(),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      final isSelected = _notesController.text == subtype.value;
      return ListTile(
        leading: Icon(_getHealthIcon(subtype.value),
            color: isSelected ? AppTheme.sante : null),
        title: Text(_resolveHealthLabel(context, subtype)),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
            : null,
        tileColor: isSelected ? AppTheme.sante.withValues(alpha: 0.15) : null,
        onTap: () => setState(() => _notesController.text = subtype.value),
      );
    }).toList();
  }

  List<Widget> _buildActionButtons() {
    return [
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: Text(context.l.saveButton),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: TextButton.icon(
          onPressed: _confirmDelete,
          icon: Icon(Icons.delete_outline,
              color: Theme.of(context).colorScheme.error, size: 20),
          label: Text(context.l.deleteButton,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
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

  String _formatDateTime(DateTime dt) {
    return formatDate(context, dt);
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

  /// Résout le label localisé pour un HealthSubtype via son labelKey.
  String _resolveHealthLabel(BuildContext ctx, HealthSubtype subtype) {
    switch (subtype.labelKey) {
      case 'healthNettoyageYeux':
        return ctx.l.healthNettoyageYeux;
      case 'healthNettoyageNombril':
        return ctx.l.healthNettoyageNombril;
      case 'healthNettoyageVisage':
        return ctx.l.healthNettoyageVisage;
      case 'healthNettoyageNez':
        return ctx.l.healthNettoyageNez;
      case 'healthVitamineD':
        return ctx.l.healthVitamineD;
      case 'healthVitamineK':
        return ctx.l.healthVitamineK;
      default:
        return subtype.label;
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

  /// Retourne l'icône pour un HealthSubtype donné.
  IconData _getHealthIcon(String value) {
    return switch (value) {
      'nettoyage_yeux' ||
      'nettoyage_nombril' ||
      'nettoyage_visage' ||
      'nettoyage_nez' =>
        Icons.cleaning_services,
      'vitamine_d' || 'vitamine_k' => Icons.medication,
      _ => Icons.health_and_safety,
    };
  }
}
