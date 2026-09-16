import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../providers/export_providers.dart';

/// Confirmation dialog for the database export.
///
/// The privacy warning is shown BEFORE anything happens. On confirm, the
/// export runs with a loading state, then the dialog surfaces the outcome
/// (success / nothing-to-export / failure) and stays open for the user to
/// close it.
class ExportDataDialog extends ConsumerStatefulWidget {
  const ExportDataDialog({super.key});

  @override
  ConsumerState<ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends ConsumerState<ExportDataDialog> {
  bool _running = false;
  ExportOutcome? _outcome;

  Future<void> _confirm() async {
    setState(() {
      _running = true;
      _outcome = null;
    });
    final outcome = await ref.read(exportControllerProvider.notifier).shareExport();
    if (mounted) {
      setState(() {
        _running = false;
        _outcome = outcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;

    if (_running) {
      return AlertDialog(
        title: Text(l.exportDataTitle),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final outcome = _outcome;
    if (outcome != null) {
      final message = switch (outcome) {
        ExportSuccess() => l.exportDataSuccess,
        ExportNothingToExport() => l.exportDataEmpty,
        ExportFailure() || ExportIdle() => l.exportDataError,
      };
      return AlertDialog(
        title: Text(l.exportDataTitle),
        content: Text(message),
        actions: [
          DialogConfirmButton(
            onPressed: () => Navigator.of(context).pop(),
            label: l.closeButton,
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(l.exportDataTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.exportDataDescription),
          const SizedBox(height: 16),
          Text(l.exportDataWarning),
        ],
      ),
      actions: [
        DialogActionButtons(
          onCancelPressed: () => Navigator.of(context).pop(),
          onConfirmPressed: _confirm,
          cancelLabel: l.cancel,
          confirmLabel: l.exportDataConfirm,
        ),
      ],
    );
  }
}
