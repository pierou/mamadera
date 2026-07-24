import 'package:flutter/material.dart';

/// Full-width confirm button for dialogs.
class DialogConfirmButton extends StatelessWidget {
  const DialogConfirmButton({
    required this.onPressed,
    required this.label,
    this.showIcon = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    if (showIcon) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.check),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

/// Full-width cancel button for dialogs.
class DialogCancelButton extends StatelessWidget {
  const DialogCancelButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

/// Row of cancel + confirm buttons for dialogs.
class DialogActionButtons extends StatelessWidget {
  const DialogActionButtons({
    required this.onCancelPressed,
    required this.onConfirmPressed,
    required this.cancelLabel,
    required this.confirmLabel,
    super.key,
  });

  final VoidCallback onCancelPressed;
  final VoidCallback? onConfirmPressed;
  final String cancelLabel;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(child: DialogCancelButton(onPressed: onCancelPressed, label: cancelLabel)),
        const SizedBox(width: 8),
        Expanded(
          child: DialogConfirmButton(
            onPressed: onConfirmPressed,
            label: confirmLabel,
            showIcon: true,
          ),
        ),
      ],
    );
  }
}
