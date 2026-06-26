import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';
import '../../../../shared/domain/entities/tracking_event.dart';

/// Résultat retourné par le formulaire d'édition (sealed class).
sealed class EditResult {
  const EditResult();
}

/// Données de mise à jour d'un événement — utilise des enums typés directement.
class UpdateResult extends EditResult {
  const UpdateResult({
    this.timestamp,
    this.duration,
    this.notes,
    this.wasteType,
    this.pipiColor,
    this.cacaColor,
  });

  final DateTime? timestamp;
  final double? duration;
  final String? notes; // health subtype value ('nettoyage_yeux'...) ou note libre
  final WasteType? wasteType;
  final PipiColor? pipiColor;
  final CacaColor? cacaColor;
}

/// Signal de suppression d'un événement.
class DeleteResult extends EditResult {
  const DeleteResult();
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
    switch (widget.event) {
      case FeedingEvent():
        return 'miam';
      case SleepEvent():
        return 'dodo';
      case DiaperEvent():
        final dt = widget.event as DiaperEvent;
        if (dt.wasteType == WasteType.pipi) return 'pipi';
        return 'caca';
      case HealthEvent():
        return 'sante';
    }
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

    // Initialise les champs selon le type d'événement (exhaustive switch).
    switch (widget.event) {
      case FeedingEvent():
        final e = widget.event as FeedingEvent;
        _duration = e.duration;
        _notesController.text = e.notes ?? '';
      case SleepEvent():
        final e = widget.event as SleepEvent;
        _duration = e.duration;
        // sleep n'a pas de notes dans le dialog (sauf si on veut en ajouter).
      case DiaperEvent():
        final e = widget.event as DiaperEvent;
        _wasteType = e.wasteType;
        _pipiColor = e.pipiColor;
        _cacaColor = e.cacaColor;
        _notesController.text = e.notes ?? '';
      case HealthEvent():
        final e = widget.event as HealthEvent;
        // Le subtype est stocké dans notes pour le health screen.
        _notesController.text = e.subtype.value;
    }
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
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null && mounted) {
        setState(() {
          _selectedDate =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      } else if (mounted) {
        // Si l'utilisateur annule le temps mais pas la date, on garde juste la date
        setState(() {
          _selectedDate = DateTime(date.year, date.month, date.day,
              _selectedDate.hour, _selectedDate.minute);
        });
      }
    }
  }

  void _submit() {
    final result = UpdateResult(
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
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'événement'),
        content: const Text(
          'Voulez-vous vraiment supprimer cet événement ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const DeleteResult());
    }
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
            Text('Modifier l\'événement',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // --- Date & Heure ---
            _buildSectionTitle('Date et heure'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(_formatDateTime(_selectedDate)),
                    const Spacer(),
                    const Icon(Icons.edit_outlined,
                        size: 18, color: Colors.white54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Durée (uniquement pour dodo) — utilise l'enum au lieu de string comparison ---
            if (_normalizedType == 'dodo') ...[
              _buildSectionTitle('Durée'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          _duration != null ? '${_duration!.toInt()}' : '',
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Minutes',
                        hintStyle: const TextStyle(color: Colors.black38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        suffixText: 'min',
                      ),
                      onChanged: (value) {
                        _duration =
                            value.isEmpty ? null : double.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // --- Type de selle & couleurs (pour caca et pipi) — utilise l'enum WasteType ---
            if (_normalizedType == 'caca' || _normalizedType == 'pipi') ...[
              // WasteType selector : uniquement pour caca (permet de switcher vers pipi/lesDeux)
              if (_normalizedType == 'caca') ...[
                _buildSectionTitle('Type'),
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
              ],

              // Couleur pipi (toujours visible pour pipi ; conditionnelle pour caca selon wasteType)
              if (_normalizedType == 'pipi' ||
                  _wasteType == WasteType.pipi ||
                  _wasteType == WasteType.lesDeux) ...[
                _buildSectionTitle('Couleur du pipi'),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: PipiColor.values.map((c) {
                    return FilterChip(
                      label: Text(c.label),
                      selected: _pipiColor == c,
                      onSelected: (_) => setState(
                          () => _pipiColor = _pipiColor == c ? null : c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Couleur caca (conditionnelle via enum)
              if (_wasteType == WasteType.caca ||
                  _wasteType == WasteType.lesDeux) ...[
                _buildSectionTitle('Couleur du caca'),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: CacaColor.values.map((c) {
                    return FilterChip(
                      label: Text(c.label),
                      selected: _cacaColor == c,
                      onSelected: (_) => setState(
                          () => _cacaColor = _cacaColor == c ? null : c),
                    );
                  }).toList(),
                ),
              ],
            ],

            // --- Notes (tous les types sauf sante et dodo) ---
            if (_normalizedType != 'sante' && _normalizedType != 'dodo') ...[
              const SizedBox(height: 20),
              _buildSectionTitle('Notes'),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Ajouter une note...',
                  hintStyle: const TextStyle(color: Colors.black38),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],

            // --- Sous-type santé (pour sante) — utilise l'enum HealthSubtype au lieu de strings ---
            if (_normalizedType == 'sante') ...[
              const SizedBox(height: 20),
              _buildSectionTitle('Type de soin'),
              // Utilise _notesController.text (mutable via setState) au lieu de widget.initialNotes (immutable)
              ...HealthSubtype.values.map((subtype) {
                final isSelected = _notesController.text == subtype.value;
                return ListTile(
                  leading: Icon(_getHealthIcon(subtype.value),
                      color: isSelected ? Colors.greenAccent : null),
                  title: Text(subtype.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: Colors.greenAccent)
                      : null,
                  tileColor: isSelected
                      ? AppTheme.sante.withValues(alpha: 0.15)
                      : null,
                  onTap: () => setState(() {
                    _notesController.text = subtype.value;
                  }),
                );
              }),
            ],

            const SizedBox(height: 24),

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check, color: Colors.black),
                label: const Text('Enregistrer',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // Bouton Supprimer (séparé visuellement)
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              label: const Text('Supprimer',
                  style: TextStyle(fontSize: 14, color: Colors.redAccent)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ],
        ),
      ),
    );
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
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} $hour:$minute';
  }

  /// Retourne le label d'un WasteType via l'enum.
  String _wasteTypeLabel(WasteType type) {
    switch (type) {
      case WasteType.pipi:
        return '🟡 Pipi';

      case WasteType.caca:
        return '🟤 Caca';
      case WasteType.lesDeux:
        return '🟡🟤 Les deux';
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
