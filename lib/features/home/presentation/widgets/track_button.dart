import 'package:flutter/material.dart';

class TrackButton extends StatefulWidget {
  const TrackButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.pendingReminders,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Number of pending reminders to display as an amber badge dot.
  /// `null` or `0` hides the badge entirely.
  final int? pendingReminders;

  @override
  State<TrackButton> createState() => _TrackButtonState();
}

class _TrackButtonState extends State<TrackButton> {
  bool _isPressed = false;

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scaleByDouble(
                _isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1, 1),
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: widget.color,
                      ),
                ),
                if (widget.pendingReminders != null &&
                    widget.pendingReminders! > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 234, 179, 8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
