import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/widgets/dialog_buttons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/import_repository.dart';
import '../providers/import_providers.dart';

/// Stages of the restore flow, driven by user action — never by a timer.
enum _ImportPhase {
  /// Destructive warning, before any file is touched.
  warning,

  /// A file is being read and parsed.
  busy,

  /// Contents shown; the second, informed confirmation.
  summary,

  /// Terminal state: success or the reason nothing was done.
  result,
}

/// Reads the backup the parent chose, or returns null when nothing was chosen.
///
/// A seam, not an abstraction for its own sake: production passes nothing and
/// gets the OS picker; a widget test passes a closure and never has to drive a
/// native dialog that no headless runner can reach.
typedef BackupReader = Future<String?> Function();

/// Confirmation dialog for restoring the database from an export file.
///
/// Three phases, and the destructive one is last by construction: warning →
/// (OS picker, then pure parse) summary with the file's real contents → result.
/// Cancelling at any point before the last button leaves the database
/// untouched, because nothing before [ImportController.applyRestore] writes.
///
/// The plugin call lives here, in the widget: the controller only ever receives
/// a JSON string, so it needs no platform fake in tests.
class ImportDataDialog extends ConsumerStatefulWidget {
  const ImportDataDialog({super.key, this.readBackup});

  /// Overrides how the file is obtained (tests). Null uses the OS picker.
  final BackupReader? readBackup;

  @override
  ConsumerState<ImportDataDialog> createState() => _ImportDataDialogState();
}

class _ImportDataDialogState extends ConsumerState<ImportDataDialog> {
  _ImportPhase _phase = _ImportPhase.warning;
  ImportCounts? _counts;
  ImportOutcome? _result;

  Future<void> _chooseFile() async {
    setState(() => _phase = _ImportPhase.busy);
    final String json;
    try {
      final read = await (widget.readBackup ?? _readPickedBackup)();
      if (read == null) {
        // Cancelled in the OS picker: nothing was read, nothing changed.
        if (mounted) setState(() => _phase = _ImportPhase.warning);
        return;
      }
      json = read;
    } on ImportFormatException catch (error) {
      // A size limit or an unreadable file is a reason with a translation, not
      // a crash and not a Dart message on screen.
      _showResult(ImportRejected(reason: error.reason));
      return;
    } catch (error) {
      // MissingPluginException, a revoked URI permission, a file moved away
      // while the picker was open — all one honest outcome.
      _showResult(const ImportRejected(reason: ImportRejectionReason.unreadableFile));
      return;
    }
    final outcome =
        await ref.read(importControllerProvider.notifier).inspectFile(json);
    if (!mounted) return;
    switch (outcome) {
      case ImportSummaryReady(:final counts):
        setState(() {
          _counts = counts;
          _phase = _ImportPhase.summary;
        });
      case ImportRejected():
      case ImportFailed():
        _showResult(outcome);
      case ImportIdle():
      case ImportSuccess():
        // Unreachable from an inspection; kept exhaustive so a new outcome
        // forces this dialog to decide what it means.
        _showResult(const ImportFailed());
    }
  }

  /// Reads the picked file into memory, or returns null when nothing was picked.
  ///
  /// Never writes anything to disk: `readAsBytes` (not `path`, which is null for
  /// a `content://` pick anyway) keeps the plaintext in memory only, and the
  /// plugin's own `saveFile`/`clearTemporaryFiles` APIs are never called.
  Future<String?> _readPickedBackup() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null) return null;

    // Reject a video or a photo before spending seconds reading it.
    final reportedLength = picked.lengthSync() ?? await picked.length();
    enforceBackupSizeLimit(knownLength: reportedLength);

    final bytes = await picked.readAsBytes();
    enforceBackupSizeLimit(knownLength: null, actualBytes: bytes.lengthInBytes);
    return _decodeUtf8(bytes);
  }

  /// Decodes the file, or rejects it as not-a-backup when it is not text.
  String _decodeUtf8(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const ImportFormatException(ImportRejectionReason.invalidJson);
    }
  }

  Future<void> _confirmRestore() async {
    setState(() => _phase = _ImportPhase.busy);
    final outcome =
        await ref.read(importControllerProvider.notifier).applyRestore();
    if (!mounted) return;
    switch (outcome) {
      case ImportSuccess():
      case ImportFailed():
        _showResult(outcome);
      case ImportIdle():
      case ImportRejected():
      case ImportSummaryReady():
        // Nothing was pending, or the document turned out unusable: go back to
        // the warning rather than claiming a restore happened.
        _dismissToWarning();
    }
  }

  void _showResult(ImportOutcome outcome) {
    if (!mounted) return;
    setState(() {
      _result = outcome;
      _phase = _ImportPhase.result;
    });
  }

  void _dismissToWarning() {
    if (!mounted) return;
    setState(() {
      _counts = null;
      _phase = _ImportPhase.warning;
    });
  }

  /// Backing out of the summary must drop the pending document, so a later open
  /// of the dialog cannot apply a stale confirmation.
  void _cancelAtSummary() {
    ref.read(importControllerProvider.notifier).cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return switch (_phase) {
      _ImportPhase.busy => AlertDialog(
          title: Text(l.importDataTitle),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      _ImportPhase.warning => _buildWarning(l),
      _ImportPhase.summary => _buildSummary(l),
      _ImportPhase.result => _buildResult(l),
    };
  }

  Widget _buildWarning(AppLocalizations l) => AlertDialog(
        title: Text(l.importDataTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.importDataDescription),
            const SizedBox(height: 16),
            Text(l.importDataWarning),
          ],
        ),
        actions: [
          DialogActionButtons(
            onCancelPressed: () => Navigator.of(context).pop(),
            onConfirmPressed: _chooseFile,
            cancelLabel: l.cancel,
            confirmLabel: l.importDataConfirm,
          ),
        ],
      );

  Widget _buildSummary(AppLocalizations l) {
    final counts = _counts;
    // A restore is only ever confirmed once the counts are known; without them
    // there is nothing to consent to, so fall back to the warning phase.
    if (counts == null) {
      return _buildWarning(l);
    }
    // Events with no profile restore fine but stay invisible until a profile
    // exists — say so now, while cancelling is still possible.
    final orphanRisk = counts.babyProfiles == 0 && counts.trackingEvents > 0;
    return AlertDialog(
      title: Text(l.importDataTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.importDataSummary(
            counts.babyProfiles,
            counts.trackingEvents,
            counts.customReminders,
          )),
          if (orphanRisk) ...[
            const SizedBox(height: 16),
            Text(l.importDataNoProfile),
          ],
        ],
      ),
      actions: [
        DialogActionButtons(
          onCancelPressed: _cancelAtSummary,
          onConfirmPressed: _confirmRestore,
          cancelLabel: l.cancel,
          confirmLabel: l.importDataProceed,
        ),
      ],
    );
  }

  Widget _buildResult(AppLocalizations l) {
    final result = _result;
    final message = switch (result) {
      ImportSuccess(:final counts) => l.importDataSuccess(
          counts.babyProfiles,
          counts.trackingEvents,
        ),
      ImportRejected(:final reason) => _rejectionMessage(l, reason),
      ImportFailed() || ImportIdle() || ImportSummaryReady() =>
        l.importDataErrorFailed,
      null => l.importDataErrorFailed,
    };
    return AlertDialog(
      title: Text(l.importDataTitle),
      content: Text(message),
      actions: [
        DialogConfirmButton(
          onPressed: () => Navigator.of(context).pop(),
          label: l.closeButton,
        ),
      ],
    );
  }

  /// One translated line per rejection reason.
  ///
  /// Several reasons share a line on purpose (a malformed row and a missing
  /// section are both "this is not a valid backup"); the enum value still
  /// distinguishes them in the log. Nothing here is built from file content.
  String _rejectionMessage(AppLocalizations l, ImportRejectionReason reason) =>
      switch (reason) {
        ImportRejectionReason.invalidJson ||
        ImportRejectionReason.missingTable ||
        ImportRejectionReason.countsMismatch ||
        ImportRejectionReason.invalidRow ||
        ImportRejectionReason.fileTooLarge =>
          l.importDataErrorInvalidFile,
        ImportRejectionReason.notAMamaderaFile => l.importDataErrorNotMamadera,
        ImportRejectionReason.newerFormatVersion => l.importDataErrorNewerVersion,
        ImportRejectionReason.newerSchemaVersion => l.importDataErrorNewerSchema,
        ImportRejectionReason.emptyFile => l.importDataErrorEmpty,
        ImportRejectionReason.unreadableFile => l.importDataErrorUnreadable,
      };
}
