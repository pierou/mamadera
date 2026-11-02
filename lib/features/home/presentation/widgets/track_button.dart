import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';
import '../../../reminders/domain/entities/reminders_state.dart';

class TrackButton extends StatefulWidget {
  const TrackButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.onLongPress,
    this.reminders,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Reminder statuses for this tracking type. Only the most recent
  /// `lastEventAt` is read, for the « last tracked » line under the label —
  /// the pending reminders themselves are listed in `HomeRemindersSection`
  /// below the grid (B23 removed the on-button pills).
  final List<ReminderStatus>? reminders;

  @override
  State<TrackButton> createState() => _TrackButtonState();
}

class _TrackButtonState extends State<TrackButton> {
  bool _isPressed = false;

  String? _lastTrackedLabel(BuildContext context) {
    final items = widget.reminders ?? [];
    if (items.isEmpty) return null;

    DateTime? lastEvent;
    for (final s in items) {
      final evt = s.lastEventAt;
      if (evt == null) continue;
      lastEvent = lastEvent == null || evt.isAfter(lastEvent) ? evt : lastEvent;
    }

    if (lastEvent == null) return null;

    final diff = DateTime.now().difference(lastEvent);

    if (diff.inMinutes < 1) return '< 1 min';
    if (diff.inHours < 1) return '${diff.inMinutes}min ago';
    if (diff.inDays < 1) return '${diff.inHours}h ${diff.inMinutes % 60}m ago';
    if (diff.inDays == 1) return context.l.yesterday;
    if (diff.inDays < 7) return '${diff.inDays}${context.l.daysAgo}';
    return '${lastEvent.day}/${lastEvent.month}/${lastEvent.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: _TrackButtonContent(
          isPressed: _isPressed,
          label: widget.label,
          icon: widget.icon,
          color: widget.color,
          context: context,
          lastTrackedLabelBuilder: _lastTrackedLabel,
        ),
      ),
    );
  }
}

/// Internal content of TrackButton, extracted to keep build method under 25 lines.
class _TrackButtonContent extends StatelessWidget {
  const _TrackButtonContent({
    required this.isPressed,
    required this.label,
    required this.icon,
    required this.color,
    required this.context,
    required this.lastTrackedLabelBuilder,
  });

  final bool isPressed;
  final String label;
  final IconData? icon;
  final Color color;
  final BuildContext context;
  final String? Function(BuildContext) lastTrackedLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return AnimatedContainer(
      duration: MediaQuery.of(this.context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..scaleByDouble(isPressed ? 0.97 : 1.0, isPressed ? 0.97 : 1.0, 1, 1),
      width: double.infinity,
      height: icon != null ? 230.0 : 200.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius:
            const BorderRadius.all(Radius.circular(AppTheme.shapeCardRadius)),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 32, color: color),
              ),
            if (icon != null) const SizedBox(height: AppTheme.spacingSm),
            Expanded(
              flex: icon != null ? 3 : 4,
              // Single line + scaleDown: a long label (FR "Nourriture") is
              // shrunk to fit instead of wrapping into an orphaned fragment.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
            if (lastTrackedLabelBuilder(this.context) != null) ...[
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    lastTrackedLabelBuilder(this.context)!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
