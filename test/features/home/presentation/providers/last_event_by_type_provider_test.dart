// The home grid's « last tracked » map (B28).
//
// These tests run against a real drift database: what the feature has to get
// right is *which rows it looks at* — one baby's own, newest per type — and a
// mocked database would only prove the call was made.

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart';
import 'package:mamadera/features/home/presentation/providers/last_event_by_type_provider.dart';
import 'package:mamadera/features/home/presentation/providers/track_notifier.dart';
import 'package:mamadera/shared/domain/entities/quantity_unit.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// The keychain is not under test here.
class _FakeEncryption extends EncryptionService {
  @override
  String encrypt(String plainText) => 'enc:$plainText';

  @override
  String? decrypt(String? cipherText) {
    if (cipherText == null || cipherText.isEmpty) return null;
    if (!cipherText.startsWith('enc:')) return null;
    return cipherText.substring('enc:'.length);
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  Future<void> addBaby(String id) async {
    await db.into(db.babyProfiles).insert(BabyProfilesCompanion.insert(
          id: id,
          name: id,
          birthDate: DateTime(2026, 6, 1).millisecondsSinceEpoch,
        ));
  }

  Future<void> addEvent(String type, DateTime at, {String? babyId}) async {
    await db.insertEvent(TrackingEventsCompanion(
      unit: const Value('ml'),
      type: Value(type),
      timestamp: Value(at),
      babyId: Value(babyId),
    ));
  }

  Future<Map<TrackingType, DateTime>> readMap() =>
      container.read(lastEventByTypeProvider.future);

  setUp(() async {
    db = AppDatabase(LazyDatabase(NativeDatabase.memory));
    await db.select(db.reminderDismissals).get();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWith((ref) async => db),
      encryptionServiceProvider.overrideWith((ref) async => _FakeEncryption()),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('lastEventByTypeProvider', () {
    test('holds one entry per type that has an event, and none otherwise',
        () async {
      await addBaby('a');
      await addEvent('miam', DateTime(2026, 11, 8, 8), babyId: 'a');
      await addEvent('dodo', DateTime(2026, 11, 9, 3), babyId: 'a');

      final map = await readMap();

      expect(map.keys, unorderedEquals({TrackingType.miam, TrackingType.dodo}),
          reason: 'a type never recorded is absent, not mapped to a sentinel');
      expect(map[TrackingType.miam], DateTime(2026, 11, 8, 8));
      expect(map.containsKey(TrackingType.caca), isFalse);
      expect(map.containsKey(TrackingType.sante), isFalse);
    });

    test('follows the active baby instead of the family', () async {
      await addBaby('a');
      await addBaby('b');
      await addEvent('miam', DateTime(2026, 11, 8), babyId: 'a');
      await addEvent('caca', DateTime(2026, 11, 9), babyId: 'b');

      expect((await readMap()).keys, {TrackingType.miam});

      // The parent switches baby in Settings: the rows the grid may speak of
      // change with it. (Reading the other baby's timestamp would be a privacy
      // story as much as a correctness one — the app shows one baby at a time.)
      await (db.update(db.babyProfiles)..where((t) => t.id.equals('a')))
          .write(const BabyProfilesCompanion(isActive: Value(false)));
      await (db.update(db.babyProfiles)..where((t) => t.id.equals('b')))
          .write(const BabyProfilesCompanion(isActive: Value(true)));
      container.invalidate(activeBabyProvider);

      final map = await readMap();
      expect(map.keys, {TrackingType.caca});
      expect(map.containsKey(TrackingType.miam), isFalse,
          reason: 'baby b never fed; the line must not borrow baby a\'s');
    });

    test('the profile-less state reads the unowned rows only', () async {
      // The state a fresh install is in, and the one a legacy v10 database
      // lands in: no profile, events with no baby_id. An event that belongs to
      // a profile is somebody's history and must not be borrowed here.
      await addEvent('sante', DateTime(2026, 11, 5));
      await addEvent('sante', DateTime(2026, 11, 7), babyId: 'a');

      expect(await readMap(), {TrackingType.sante: DateTime(2026, 11, 5)});
    });

    test('a tracked event puts its own line on the button', () async {
      // Freshness, not plumbing: `TrackNotifier` invalidates this provider after
      // a successful insert, which is what makes the line appear without
      // restarting the app — and it is why the line is no longer a side effect
      // of the reminder poll.
      await addBaby('a');
      expect(await readMap(), isEmpty);

      await container.read(trackNotifierProvider.notifier).track(
            type: TrackingType.miam,
            quantity: 100,
            unit: QuantityUnit.ml,
            feedingSubtype: FeedingSubtype.natural,
          );

      final map = await readMap();
      expect(map.containsKey(TrackingType.miam), isTrue);
      expect(map[TrackingType.miam]!.difference(DateTime.now()).inMinutes.abs(),
          lessThan(2),
          reason: 'the line reads the event just recorded, now');
    });
  });
}
