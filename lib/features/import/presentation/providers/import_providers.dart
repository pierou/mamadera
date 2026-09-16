import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/any_baby_exists_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/encryption_provider.dart';
import '../../../../core/services/app_logger.dart';
import '../../../baby/presentation/providers/baby_profile_providers.dart';
import '../../../history/presentation/providers/history_notifier.dart';
import '../../../history/presentation/providers/history_repository_provider.dart';
import '../../../home/presentation/providers/repository_provider.dart';
import '../../../menu/presentation/providers/menu_repository_provider.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';
import '../../data/repositories/import_repository_impl.dart';
import '../../domain/repositories/import_repository.dart';

/// Provider for the import repository implementation.
///
/// Exposed under the domain interface [ImportRepository] so the presentation
/// layer depends on the abstraction (and tests can override a fake). Deliberately
/// NOT invalidated by a successful restore: the controller holds the parsed
/// document between the two confirmations, and discarding the repository would
/// discard the restore in progress.
final importRepositoryProvider = FutureProvider<ImportRepository>((ref) async {
  final encryption = await ref.read(encryptionServiceProvider.future);
  final database = await ref.watch(databaseProvider.future);
  return ImportRepositoryImpl(database: database, encryption: encryption);
});

/// Result of an import attempt, surfaced to the UI.
sealed class ImportOutcome {
  const ImportOutcome();
}

/// Initial state: no file inspected yet.
class ImportIdle extends ImportOutcome {
  const ImportIdle();
}

/// The file was rejected before anything was written; [reason] decides the one
/// translated message shown, and is a closed set on purpose (see
/// [ImportRejectionReason]).
class ImportRejected extends ImportOutcome {
  const ImportRejected({required this.reason});

  /// Why the file was refused. Never contains file content, name or path.
  final ImportRejectionReason reason;
}

/// The file parsed and validated; carries what the confirmation summary shows.
class ImportSummaryReady extends ImportOutcome {
  const ImportSummaryReady({required this.counts});

  /// Contents of the backup, so the parent can consent with open eyes.
  final ImportCounts counts;
}

/// The restore committed; carries what was written.
class ImportSuccess extends ImportOutcome {
  const ImportSuccess({required this.counts});

  /// Rows actually restored.
  final ImportCounts counts;
}

/// The restore failed. The transaction rolled back, so the previous database is
/// intact — which is exactly what the dialog says, and the only reason this
/// state needs no detail string.
class ImportFailed extends ImportOutcome {
  const ImportFailed();
}

/// Drives the two-step restore: inspect a file (pure) → show the summary →
/// apply it (the one destructive call).
///
/// The split is the safety story: nothing before [applyRestore] can change the
/// database, and [applyRestore] either commits fully or not at all. The parsed
/// document is held in [_pending] so the destructive step restores exactly what
/// the parent was shown, not a re-parse that could differ.
class ImportController extends AsyncNotifier<ImportOutcome> {
  static final Logger _logger = appLogger();

  ParsedExport? _pending;

  @override
  ImportOutcome build() => const ImportIdle();

  /// Parses and validates [json]; on success the outcome carries the row counts
  /// for the confirmation dialog. Performs no write.
  Future<ImportOutcome> inspectFile(String json) =>
      _run(() async {
        final repository = await ref.read(importRepositoryProvider.future);
        final parsed = await repository.parseExport(json);
        if (!ref.mounted) return const ImportIdle();
        _pending = parsed;
        return ImportSummaryReady(counts: parsed.counts);
      });

  /// Applies the pending document: replaces all five tables in one transaction,
  /// then refreshes every provider that could still be showing pre-import data.
  ///
  /// Returns [ImportIdle] when nothing is pending (a dialog that somehow
  /// confirmed twice) — never a partial guess.
  Future<ImportOutcome> applyRestore() async {
    final pending = _pending;
    if (pending == null) return const ImportIdle();
    return _run(() async {
      final repository = await ref.read(importRepositoryProvider.future);
      final counts = await repository.restore(pending);
      // Committed: the pending document is spent, and the UI can no longer
      // re-apply it by accident.
      _pending = null;
      _invalidateRestoredState();
      _logger.d('applyRestore: restored ${counts.trackingEvents} events');
      return ImportSuccess(counts: counts);
    });
  }

  /// Drops any pending restore (dialog dismissed at the summary step).
  void cancel() {
    _pending = null;
    if (ref.mounted) state = const AsyncData<ImportOutcome>(ImportIdle());
  }

  /// Runs [action], turning a rejection into [ImportRejected] and any other
  /// failure into [ImportFailed].
  ///
  /// No message text is ever carried out of here: reasons are enum values, and
  /// unexpected errors are logged with their stack but surface as a generic
  /// state, so no path, URI or Dart type can reach the screen.
  Future<ImportOutcome> _run(
    Future<ImportOutcome> Function() action,
  ) async {
    if (ref.mounted) state = const AsyncLoading<ImportOutcome>();
    final outcome = await _attempt(action);
    if (ref.mounted) state = AsyncData<ImportOutcome>(outcome);
    return outcome;
  }

  /// Maps a thrown rejection to [ImportRejected] and anything else to
  /// [ImportFailed]; see [_run] for why nothing carries message text.
  Future<ImportOutcome> _attempt(
    Future<ImportOutcome> Function() action,
  ) async {
    try {
      return await action();
    } on ImportFormatException catch (error) {
      _logger.d('import rejected: $error');
      _pending = null;
      return ImportRejected(reason: error.reason);
    } catch (error, stackTrace) {
      _logger.e('import failed', error: error, stackTrace: stackTrace);
      return const ImportFailed();
    }
  }

  /// Re-reads everything a restore can have changed.
  ///
  /// Unlike `menu_screen._performReset`, this must NOT invalidate
  /// [databaseProvider]: the reset closes the connection and deletes the file,
  /// which is why it rebuilds the database. A restore changes only rows in the
  /// same open file, and `databaseProvider` has no `ref.onDispose` closing the
  /// instance it hands out — invalidating it would open a second connection (and
  /// a second background isolate) per restore, while this controller kept using
  /// the first.
  ///
  /// The repository providers are invalidated instead, and everything that
  /// `ref.watch`es them is rebuilt by the cascade: `customRemindersProvider` and
  /// `reminderSettingsProvider` watch `remindersRepositoryProvider` for exactly
  /// this reason. The notifiers that *read* their repository (rather than watch
  /// it) are listed by hand, because no edge would carry the change to them.
  void _invalidateRestoredState() {
    ref
      ..invalidate(trackingRepositoryProvider)
      ..invalidate(historyRepositoryProvider)
      ..invalidate(babyProfileRepositoryProvider)
      ..invalidate(remindersRepositoryProvider)
      ..invalidate(menuRepositoryProvider)
      ..invalidate(babyProfileProvider)
      ..invalidate(activeBabyProvider)
      ..invalidate(babyProfileListProvider)
      ..invalidate(anyBabyExistsProvider)
      // Family provider: invalidating the family invalidates every live filter.
      ..invalidate(historyNotifierProvider);
  }
}

/// Provider for the import controller.
///
/// Not autoDispose: the confirmation summary lives in the controller's pending
/// document, and a dialog rebuild must not throw the parent's decision away.
final importControllerProvider =
    AsyncNotifierProvider<ImportController, ImportOutcome>(ImportController.new);
