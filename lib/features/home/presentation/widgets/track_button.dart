import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/theme.dart';

class TrackButton extends StatefulWidget {
  const TrackButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.onLongPress,
    this.lastEventAt,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// When this tracking type was last recorded, from `lastEventByTypeProvider`;
  /// `null` renders no line at all.
  ///
  /// It is **event history**, not reminder state (B28): the pending reminders
  /// live in `HomeRemindersSection` below the grid, and a line fed by them used
  /// to vanish as soon as a reminder was settled — which is what left Health as
  /// the only button ever showing one (B23 had removed the on-button pills).
  final DateTime? lastEventAt;

  @override
  State<TrackButton> createState() => _TrackButtonState();
}

class _TrackButtonState extends State<TrackButton> {
  bool _isPressed = false;

  String? _lastTrackedLabel(BuildContext context) {
    final lastEvent = widget.lastEventAt;

    if (lastEvent == null) return null;

    // B25: the line reads localized end to end — the prepared `lastTracked`
    // prefix plus the app's existing duration keys (B23's known follow-up
    // asked for three new keys; these reuse the ones that exist, so the
    // string set stays under owner review rather than growing).
    final l = context.l;
    final diff = DateTime.now().difference(lastEvent);

    if (diff.inMinutes < 1) {
      return '${l.lastTracked}< 1 min'; // same compact unit in all three locales
    }
    if (diff.inHours < 1) {
      return '${l.lastTracked}${l.durationFormatMinutes(diff.inMinutes)}';
    }
    if (diff.inDays < 1) {
      return '${l.lastTracked}'
          '${l.durationFormatHoursMinutes(diff.inHours, diff.inMinutes % 60)}';
    }
    if (diff.inDays == 1) {
      return '${l.lastTracked}${_lowerFirst(l.yesterday)}';
    }
    if (diff.inDays < 7) {
      return '${l.lastTracked}${diff.inDays}${l.daysAgo}';
    }
    return '${l.lastTracked}${lastEvent.day}/${lastEvent.month}/${lastEvent.year}';
  }

  /// 'Hier' → 'hier': the `yesterday` key is capitalised for standalone use;
  /// mid-line after the prefix it reads lower-case in all three locales.
  static String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

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
                    // B4: the label was painted with the accent itself —
                    // 1.15:1 sampled on device for miam in light mode. The
                    // tint stays in the background, border and icon; the
                    // text takes the guaranteed-contrast primary (the chip
                    // fix's structural pattern, measured 15.29:1 in v1.3.0).
                    color: theme.colorScheme.onSurface,
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
