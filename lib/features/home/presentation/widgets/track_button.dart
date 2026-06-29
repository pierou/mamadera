import 'package:flutter/material.dart';

class TrackButton extends StatefulWidget {
  const TrackButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

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
          transform: Matrix4.identity()..scaleByDouble(_isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1, 1),
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: widget.color,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
