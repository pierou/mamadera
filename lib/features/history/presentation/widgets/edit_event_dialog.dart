import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../shared/domain/entities/tracking_enums.dart';

/// Résultat retourné par le formulaire d'édition (sealed class).
sealed class EditResult {
  const EditResult();
}

/// Données de mise à jour d'un événement.
class UpdateResult extends EditResult {
  const UpdateResult({
    this.timestamp,
    this.duration,
    this.notes,
    this.wasteType,
    this.color,
  });

  final DateTime? timestamp;
  final double? duration;
  final String? notes; // health subtypes stockés ici ('nettoyage_yeux'...)
  final String? wasteType; // backward compat : valeur DB snake_case
  final String? color; // backward compat : couleur ou pipe-délimitée

  /// Retourne le WasteType typed à partir de la valeur DB.
  WasteType? get wasteTypeEnum => WasteType.fromDbValue(wasteType);

  /// Parse les couleurs initiales depuis le format DB (pipe-délimité pour les_deux).
  PipiColor? get pipiColorEnum {
    if (wasteTypeEnum != WasteType.pipi && wasteTypeEnum != WasteType.lesDeux) {
      return null;
    }
    final parts = color?.split('|') ?? [];
    final value = parts.isNotEmpty ? parts.first.trim() : null;
    return value != null ? PipiColor.byValue(value) : null;
  }

  /// Parse les couleurs initiales depuis le format DB (pipe-délimité pour les_deux).
  CacaColor? get cacaColorEnum {
    if (wasteTypeEnum != WasteType.caca && wasteTypeEnum != WasteType.lesDeux) {
      return null;
    }
    final parts = color?.split('|') ?? [];
    String value;
    if (wasteTypeEnum == WasteType.lesDeux && parts.length >= 2) {
      value = parts[1].trim();
    } else if (parts.isNotEmpty) {
      value = parts.first.trim();
    } else {
      return null;
    }
    return CacaColor.byValue(value);
  }

  /// Retourne la valeur DB formatée pour color.
  String? get colorDbValue => _buildColorString();

  String? _buildColorString() {
    final wt = wasteTypeEnum ?? WasteType.fromDbValue(wasteType);
    if (wt == null) {
      return null;
    }
    switch (wt) {
      case WasteType.pipi:
        return pipiColorEnum?.value;
      case WasteType.caca:
        return cacaColorEnum?.value;
      case WasteType.lesDeux:
        final p = pipiColorEnum?.value ?? '';
        final c = cacaColorEnum?.value ?? '';
        if (p.isNotEmpty && c.isNotEmpty) {
          return '$p|$c';
        }
        return p.isEmpty ? c : p;
    }
  }

  /// Retourne le HealthSubtype correspondant aux notes.
  HealthSubtype? get healthSubtype => HealthSubtype.byValue(notes!);
}

/// Signal de suppression d'un événement.
class DeleteResult extends EditResult {
  const DeleteResult();
}

/// Bottom sheet pour éditer les champs modifiables d'un événement.
class EditEventDialog extends ConsumerStatefulWidget {
  const EditEventDialog({
    required this.type,
    required this.initialTimestamp,
    required this.initialDuration,
    required this.initialNotes,
    required this.initialWasteType,
    required this.initialColor,
    super.key,
  });

  /// Type de l'événement (non modifiable dans ce formulaire).
  final String type; // label affiché (ex: 'Caca', 'Miam')
  final DateTime initialTimestamp;
  final double? initialDuration;
  final String?
      initialNotes; // health subtypes stockés ici ('nettoyage_yeux'...)
  final String? initialWasteType; // backward compat : valeur DB snake_case
  final String? initialColor; // backward compat : couleur ou pipe-délimitée

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
  String get _normalizedType => widget.type.toLowerCase().replaceAll('é', 'e');

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialTimestamp;
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _duration = widget.initialDuration;

    // Parse le wasteType initial depuis la valeur DB (backward compat)
    _wasteType = WasteType.fromDbValue(widget.initialWasteType);

    // Parse les couleurs initiales (format pipi|caca pour les_deux)
    if (widget.initialColor != null && widget.initialColor!.isNotEmpty) {
      final parts = widget.initialColor!.split('|');

      switch (_wasteType) {
        case WasteType.pipi:
          _pipiColor = PipiColor.byValue(parts.first.trim());
        case WasteType.caca:
          _cacaColor = CacaColor.byValue(parts.first.trim());
        case WasteType.lesDeux:
          if (parts.length >= 2) {
            _pipiColor = PipiColor.byValue(parts[0].trim());
            _cacaColor = CacaColor.byValue(parts[1].trim());
          } else if (parts.isNotEmpty) {
            // Fallback : essaie d'abord comme couleur pipi, puis caca
            _pipiColor = PipiColor.byValue(parts.first.trim()) ??
                CacaColor.byValue(parts.first.trim()) as PipiColor?;
          }
        case null:
          break;
      }
    }

    // Si les notes correspondent à un HealthSubtype, on met en surbrillance le bon item
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
      notes:
          _notesController.text.isEmpty ? null : _notesController.text.trim(),
      wasteType:
          _wasteType?.dbValue ?? widget.initialWasteType, // backward compat
      color: _buildColorDbString() ?? widget.initialColor, // backward compat
    );
    Navigator.pop(context, result);
  }

  /// Construit la chaîne de couleur finale selon le wasteType (format DB).
  String? _buildColorDbString() {
    if (_wasteType == null) {
      return null;
    }
    switch (_wasteType!) {
      case WasteType.pipi:
        return _pipiColor?.value;
      case WasteType.caca:
        return _cacaColor?.value;
      case WasteType.lesDeux:
        final p = _pipiColor?.value ?? '';
        final c = _cacaColor?.value ?? '';
        if (p.isNotEmpty && c.isNotEmpty) {
          return '$p|$c';
        }
        return p.isEmpty ? c : p;
    }
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

            // --- Type de selle & couleurs (uniquement pour caca) — utilise l'enum WasteType ---
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

              // Couleur pipi (conditionnelle via enum)
              if (_wasteType == WasteType.pipi ||
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

            // --- Notes (tous les types sauf sante qui a des sous-types fixes) ---
            if (_normalizedType != 'sante') ...[
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
              ...HealthSubtype.values.map((subtype) {
                final isSelected = widget.initialNotes == subtype.value;
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
