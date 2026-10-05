import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../core/widgets/event_date_time_field.dart';

/// What the sleep bottom sheet hands back: when the nap started, and how long
/// it lasted in minutes.
typedef SleepSelection = ({DateTime start, double minutes});

class DurationPickerDialog extends StatefulWidget {
  const DurationPickerDialog({
    required this.onSleepSelected,
    this.initialMinutes = 30.0,
    super.key,
  });

  final void Function(SleepSelection result) onSleepSelected;
  final double initialMinutes;

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  /// Pas du stepper +/- : identique au pas du slider (96 crans sur 480 min).
  static const double _stepMinutes = 5;

  late double _selectedMinutes;

  /// Répétition du stepper au long-appui : annulée en [dispose], sinon un feu
  /// post-démontage appellerait `setState` sur un State mort.
  Timer? _repeatTimer;

  /// Start pinned by the user, or null while the start stays derived from the
  /// duration: a sleep log is usually written *after* the nap, so the event is
  /// dated `now - duration` unless the parent picked a moment explicitly.
  DateTime? _pinnedStart;

  /// The moment the nap is recorded as starting: the pinned choice if there is
  /// one, otherwise "now minus the duration just entered". Recomputing on every
  /// rebuild is deliberate — it keeps the row honest with the slider.
  DateTime get _effectiveStart => _pinnedStart ??
      DateTime.now().subtract(Duration(minutes: _selectedMinutes.round()));

  /// Un cran de stepper : clamped aux bornes du slider, et no-op si on est
  /// déjà dessus (garde-fou pour la répétition au long-appui).
  void _nudgeMinutes(int direction) {
    final atBound = direction > 0
        ? _selectedMinutes >= 480
        : _selectedMinutes <= 0;
    if (atBound) return;
    setState(() {
      _selectedMinutes = (_selectedMinutes + direction * _stepMinutes).clamp(0.0, 480.0);
    });
  }

  /// Long-appui : un cran immédiat, puis un cran toutes les 120 ms.
  void _startRepeat(int direction) {
    _stopRepeat();
    _nudgeMinutes(direction);
    _repeatTimer =
        Timer.periodic(const Duration(milliseconds: 120), (_) => _nudgeMinutes(direction));
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  /// Bouton d'un cran : tooltip et label sémantique localisés, désactivé
  /// (jamais masqué — un contrôle qui disparaît fait sauter la mise en page)
  /// quand on est déjà sur la borne correspondante.
  ///
  /// [InkResponse] plutôt qu'un [GestureDetector] maison : `IconButton`
  /// n'expose pas `onLongPressStart`, mais `InkResponse` donne `onLongPress`
  /// (où l'on arme la répétition) et `onLongPressUp` (où on la coupe), avec le
  /// ripple, le focus et le tap simulé du lecteur d'écran.
  Widget _buildStepButton(int direction) {
    final label = direction > 0 ? context.l.increment : context.l.decrement;
    final atBound =
        direction > 0 ? _selectedMinutes >= 480 : _selectedMinutes <= 0;
    return Tooltip(
      message: label,
      child: InkResponse(
        borderRadius: BorderRadius.circular(24),
        onTap: atBound ? null : () => _nudgeMinutes(direction),
        onLongPress: atBound ? null : () => _startRepeat(direction),
        onLongPressUp: _stopRepeat,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            direction > 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: atBound
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.initialMinutes;
  }

  void _onMinutesChanged(double minutes) {
    // When no start is pinned, the getter recomputes `now - duration` on the
    // next build. A pinned start is an explicit user choice: changing the
    // duration must not silently slide it back to `now - newDuration`.
    setState(() => _selectedMinutes = minutes);
  }

  String _formatDuration(double minutes) {
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    if (hours > 0) {
      return '${hours}h${mins.toString().padLeft(2, '0')}';
    }
    return '$mins min';
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
            Text(
              context.l.durationPickerTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Center(
              // `scaleDown` : identité visuelle quand la ligne tient, et
              // réduction au lieu d'un overflow quand la feuille est étroite.
              // (Le titre fait 56 px : plus large que certaines largeurs de
              // sheet, même sans les boutons.)
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStepButton(-1),
                    Text(
                      _formatDuration(_selectedMinutes),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 56,
                            color: AppTheme.dodo,
                          ),
                    ),
                    _buildStepButton(1),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.dodo,
                inactiveTrackColor: Theme.of(context).colorScheme.outline,
                thumbColor: AppTheme.dodo,
                overlayColor: AppTheme.dodo.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _selectedMinutes.clamp(0.0, 480.0),
                min: 0,
                max: 480, // 8 heures max
                divisions: 96, // pas de 5 minutes
                label: _formatDuration(_selectedMinutes),
                onChanged: _onMinutesChanged,
              ),
            ),
            const SizedBox(height: 24),

            EventDateTimeField(
              value: _effectiveStart,
              onChanged: (date) => setState(() => _pinnedStart = date),
            ),

            const SizedBox(height: 24),
            DialogActionButtons(
              onCancelPressed: () => Navigator.pop(context),
              onConfirmPressed: () => widget.onSleepSelected(
                (start: _effectiveStart, minutes: _selectedMinutes),
              ),
              cancelLabel: context.l.cancelButton,
              confirmLabel: context.l.confirmButton,
            ),
          ],
        ),
      ),
    );
  }
}
