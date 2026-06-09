import 'package:flutter/material.dart';
import '../core/theme.dart';

class TrackButton extends StatefulWidget {
  const TrackButton(
      {required this.label,
      required this.color,
      required this.onTap,
      super.key});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<TrackButton> createState() => _TrackButtonState();
}

class _TrackButtonState extends State<TrackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              const BoxShadow(
                  color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: Center(
            child: Text(widget.label,
                style: AppTheme.theme.textTheme.headlineLarge),
          ),
        ),
      ),
    );
  }
}
