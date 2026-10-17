import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/export/data/repositories/export_repository_impl.dart';
import 'package:mamadera/features/export/presentation/providers/export_providers.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

/// Identity encryption spoofing: The "nothing to export" path is not achievable.
/// It's never possible to decrypt it, but in any case, we're not accessing the keychain.
class _NoopEncryption extends EncryptionService {
  @override
  String encrypt(String plainText) => plainText;

  @override
  String? decrypt(String? cipherText) => cipherText;
}

void main() {
  group('ExportController.shareExport — base vide', () {
    late AppDatabase database;
    late ProviderContainer container;

    setUp(() async {
      final connection = LazyDatabase(NativeDatabase.memory);
      database = AppDatabase(connection);
      // Trigger the migration process to create the tables.
      await database.select(database.reminderDismissals).get();

      // The repository points to an empty in-memory database: the control.
      // "nothing to export" is processed before `getTemporaryDirectory/share`, so...
      // The sharing platform is never called within this test.
      final repository = ExportRepositoryImpl(
        database: database,
        encryption: _NoopEncryption(),
      );
      container = ProviderContainer(
        overrides: [
          exportRepositoryProvider.overrideWith((ref) async => repository),
          databaseProvider.overrideWith((ref) async => database),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('renvoie ExportNothingToExport sans ouvrir la feuille de partage',
        () async {
      final outcome =
          await container.read(exportControllerProvider.notifier).shareExport();

      expect(outcome, isA<ExportNothingToExport>());
      expect(
        container.read(exportControllerProvider).value,
        isA<ExportNothingToExport>(),
      );
    });

    test('le repository confirme une base vide (comptage croisé)', () async {
      final repository = await container.read(exportRepositoryProvider.future);
      final counts = await repository.counts();

      expect(counts.babyProfiles, 0);
      expect(counts.trackingEvents, 0);
      expect(counts.reminderSettings, 0);
      expect(counts.reminderDismissals, 0);
      expect(counts.measurements, 0);
      expect(counts.reminderCompletions, 0);
      expect(counts.isEmpty, isTrue);
    });
  });

  /// Plateforme de partage enregistreuse.
  ///
  /// Unique instance for the entire file: `SharePlus.instance` is a...
  /// `static final` which captures `SharePlatform.instance` upon its first access.
  /// Therefore, an instance that is replaced between two tests would be silently replaced.
  /// It was being ignored. Instead, we reset the values to zero in the `setUp` method.
  final sharePlatform = _RecordingSharePlatform();

  group('ExportController.shareExport — flux réel', () {
    late AppDatabase database;
    late Directory tempDir;
    late ProviderContainer container;
    late ExportController controller;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('mamadera_export_test');
      SharePlatform.instance = sharePlatform;
      PathProviderPlatform.instance = _TempDirPathProvider(tempDir);
      sharePlatform.reset();

      final connection = LazyDatabase(NativeDatabase.memory);
      database = AppDatabase(connection);
      await database.select(database.reminderDismissals).get();
      await database.insertBabyProfile(
        BabyProfilesCompanion.insert(
          id: 'baby_1',
          name: 'Bébé Test',
          birthDate: 1700000000000,
        ),
      );
      await database.insertEvent(
        TrackingEventsCompanion.insert(
          unit: 'min',
          type: 'dodo',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            1700000000000,
            isUtc: true,
          ),
          duration: const Value(45),
        ),
      );

      container = ProviderContainer(
        overrides: [
          exportRepositoryProvider.overrideWith(
            (ref) async => ExportRepositoryImpl(
              database: database,
              encryption: _NoopEncryption(),
            ),
          ),
          databaseProvider.overrideWith((ref) async => database),
        ],
      );
      controller = container.read(exportControllerProvider.notifier);
    });

    tearDown(() {
      container.dispose();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      return database.close();
    });

    test('le fichier existe au moment du partage, puis a disparu', () async {
      final outcome = await controller.shareExport();

      expect(outcome, isA<ExportSuccess>());
      expect(
        (outcome as ExportSuccess).counts.trackingEvents,
        1,
      );
      expect(sharePlatform.calls, hasLength(1));
      // The file must be readable WHEN the sharing sheet accesses it.
      // The reverse test would demonstrate that there is no data being exported to iOS/Android.
      expect(sharePlatform.fileExistedDuringShare, isTrue);
      expect(
          sharePlatform.contentDuringShare, contains('"exportFormatVersion"'));
      expect(sharePlatform.contentDuringShare, contains('dodo'));
      // Confidentiality invariant: No plaintext copies survive.
      expect(tempDir.listSync(), isEmpty);
    });

    test('nom de fichier daté et extensible JSON', () async {
      await controller.shareExport();

      final shared = sharePlatform.calls.single.files!.single.path;
      expect(
        shared,
        matches(r'mamadera-export-\d{8}-\d{6}\.json$'),
      );
      expect(shared, startsWith(tempDir.path));
    });

    test('le partage ne reçoit jamais la clé de chiffrement', () async {
      await controller.shareExport();

      final content = sharePlatform.contentDuringShare!;
      expect(content, isNot(contains('key')));
      expect(content, isNot(contains(tempDir.path)));
    });

    test('le fichier temporaire est supprimé même si le partage échoue',
        () async {
      sharePlatform.errorToThrow = StateError('share sheet unavailable');

      final outcome = await controller.shareExport();

      expect(outcome, isA<ExportFailure>());
      expect(tempDir.listSync(), isEmpty);
    });

    test('base vidée : ni feuille de partage, ni fichier écrit', () async {
      await database.delete(database.trackingEvents).go();
      await database.delete(database.babyProfiles).go();

      final outcome = await controller.shareExport();

      expect(outcome, isA<ExportNothingToExport>());
      expect(sharePlatform.calls, isEmpty);
      expect(tempDir.listSync(), isEmpty);
    });
  });
}

/// Simulated sharing platform: It records the data it receives and can...
/// fail to meet demand.
class _RecordingSharePlatform extends SharePlatform {
  final List<ShareParams> calls = <ShareParams>[];
  Object? errorToThrow;
  bool fileExistedDuringShare = false;
  String? contentDuringShare;

  void reset() {
    calls.clear();
    errorToThrow = null;
    fileExistedDuringShare = false;
    contentDuringShare = null;
  }

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    final file = File(params.files!.single.path);
    fileExistedDuringShare = file.existsSync();
    if (fileExistedDuringShare) {
      contentDuringShare = file.readAsStringSync();
    }
    final error = errorToThrow;
    if (error != null) throw error;
    return const ShareResult('test', ShareResultStatus.success);
  }
}

/// Provides a genuine temporary directory to the controller, without requiring any plugins.
class _TempDirPathProvider extends PathProviderPlatform {
  _TempDirPathProvider(this._tempDir);

  final Directory _tempDir;

  @override
  Future<String?> getTemporaryPath() async => _tempDir.path;
}
