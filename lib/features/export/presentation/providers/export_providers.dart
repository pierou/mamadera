import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/encryption_provider.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/repositories/export_repository_impl.dart';
import '../../domain/repositories/export_repository.dart';

/// Provider for the export repository implementation.
///
/// Exposed under the domain interface [ExportRepository] so the presentation
/// layer depends on the abstraction (and tests can override a fake).
final exportRepositoryProvider = FutureProvider<ExportRepository>((ref) async {
  final encryption = await ref.read(encryptionServiceProvider.future);
  final database = await ref.watch(databaseProvider.future);
  return ExportRepositoryImpl(database: database, encryption: encryption);
});

/// Result of an export attempt, surfaced to the UI.
sealed class ExportOutcome {
  const ExportOutcome();
}

/// Initial state: the controller has not been asked to export yet.
class ExportIdle extends ExportOutcome {
  const ExportIdle();
}

/// The database had neither baby profile nor tracking event: no temp file
/// was written and the share sheet was NOT opened.
class ExportNothingToExport extends ExportOutcome {
  const ExportNothingToExport();
}

/// The export file was handed to the system share sheet.
class ExportSuccess extends ExportOutcome {
  const ExportSuccess({required this.counts});

  /// Row counts of what was in the shared file.
  final ExportCounts counts;
}

/// The export failed after the confirmation was pressed.
class ExportFailure extends ExportOutcome {
  const ExportFailure({required this.message});

  /// Human-facing error message.
  final String message;
}

/// Drives the export flow: build the JSON → write a temp file → hand it to
/// the system share sheet → delete the temp file.
class ExportController extends AsyncNotifier<ExportOutcome> {
  static final Logger _logger = appLogger();

  @override
  ExportOutcome build() => const ExportIdle();

  /// Runs the export and hands the file to the system share sheet.
  ///
  /// The temp file is ALWAYS deleted in a `finally` block (best effort,
  /// deletion failure ignored): plaintext health data must not linger on
  /// disk after the user has been given the file.
  Future<ExportOutcome> shareExport() async {
    state = const AsyncLoading<ExportOutcome>();
    final guarded = await AsyncValue.guard(_run);
    state = guarded;
    final error = guarded.asError;
    if (error != null) {
      _logger.e('shareExport failed', error: error.error, stackTrace: error.stackTrace);
      return ExportFailure(message: error.error.toString());
    }
    return guarded.value!;
  }

  Future<ExportOutcome> _run() async {
    final repository = await ref.read(exportRepositoryProvider.future);

    // Nothing-to-export check FIRST: no temp file, no share sheet.
    final counts = await repository.counts();
    if (counts.isEmpty) return const ExportNothingToExport();

    final json = await repository.buildExportJson();

    final tempDir = await getTemporaryDirectory();
    // `tempDir.path`, never `'$tempDir'`: interpolating the Directory object
    // itself yields "Directory: '/…'" and produces a bogus relative path that
    // can never be written.
    final file = File('${tempDir.path}/${_fileName(DateTime.now())}');
    try {
      await file.writeAsString(json);
      // SharePlus.instance.share(ShareParams(...)) is the current API — the
      // legacy static `Share` entry points are @Deprecated and this repo
      // compiles with --fatal-warnings, so they must not appear.
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      return ExportSuccess(counts: counts);
    } finally {
      // Deleting here is safe on both platforms, verified against share_plus
      // 13.3.0 rather than assumed: Android copies the file into its own
      // cacheDir/share_plus and shares THAT copy, while iOS completes the
      // method channel from UIActivityViewController.completionWithItemsHandler,
      // i.e. only after the sheet is dismissed — so the receiver never reads a
      // file we already removed. Do not move this delete earlier (empty file)
      // and do not drop it (plaintext notes would linger in the cache).
      // Best effort: ignore deletion failure; the next export simply writes a
      // fresh timestamped name.
      try {
        await file.delete();
      } catch (_) {
        // Nothing to do — the cleanup is best effort by design.
      }
    }
  }

  /// `mamadera-export-YYYYMMDD-HHmmss.json` from the local clock.
  String _fileName(DateTime now) {
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return 'mamadera-export-$stamp.json';
  }
}

/// Provider for the export controller.
final exportControllerProvider =
    AsyncNotifierProvider<ExportController, ExportOutcome>(ExportController.new);
