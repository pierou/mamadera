import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/reminders/domain/services/notification_payload.dart';

/// The identity a notification carries so a tap can say what fired (B15, D-R9).
///
/// The strict half of this contract is "identity = scope + stable item id, never
/// the OS id or the plan index" (B15's "Do not"); the tolerant half is that the
/// string comes back from the OS and may be anything — including nothing at all.
void main() {
  group('ReminderNotificationPayload', () {
    test('a scope and an id round trip', () {
      const payload = ReminderNotificationPayload(
        scope: 'baby-1',
        itemId: 'vitamine_d',
      );
      final decoded = ReminderNotificationPayload.tryParse(payload.encode());
      expect(decoded?.scope, 'baby-1');
      expect(decoded?.itemId, 'vitamine_d');
    });

    test('the profileless scope round trips as the sentinel, not as null', () {
      // `''` is a real scope in this schema (legacy installs without a profile);
      // collapsing it to `null` on the way out would make a tap for that scope
      // indistinguishable from a tap with no payload.
      const payload = ReminderNotificationPayload(scope: '', itemId: 'miam');
      final decoded = ReminderNotificationPayload.tryParse(payload.encode());
      expect(decoded?.scope, '');
      expect(decoded?.scopeOrNull, isNull,
          reason:
              'the repository maps `null` to the sentinel, so the reader does');
      expect(ReminderNotificationPayload(scope: 'b', itemId: 'x').scopeOrNull,
          'b');
    });

    test('an id with characters that need escaping survives', () {
      // Not hypothetical for a scope: baby ids are strings this app does not
      // constrain, and a naive `split`-based encoding would corrupt one holding a
      // quote or a colon. JSON is the reason the encoding is not `a:b`.
      const payload = ReminderNotificationPayload(
        scope: 'baby "1":x',
        itemId: 'custom_7',
      );
      final decoded = ReminderNotificationPayload.tryParse(payload.encode());
      expect(decoded?.scope, 'baby "1":x');
      expect(decoded?.itemId, 'custom_7');
    });

    test('absent, empty, non-JSON and foreign JSON all read as no payload', () {
      for (final raw in <String?>[
        null,
        '',
        'vitamine_d',
        '{not json',
        '[1,2]',
        '{"b":"baby-1"}', // no item
        '{"i":"vitamine_d"}', // no scope
        '{"b":null,"i":"vitamine_d"}',
        '{"b":"baby-1","i":""}', // an empty id resolves to nothing
        '{"b":"baby-1","i":7}',
      ]) {
        expect(ReminderNotificationPayload.tryParse(raw), isNull,
            reason: '$raw');
      }
    });

    test(
        'the encoding is the documented shape (a foreign reader, a future bug)',
        () {
      // Pinned as JSON with the two short keys, because the string is handed to the
      // OS and may be read back by a *different build* of the app after an upgrade.
      // A silent reshape would read as "no payload" on those old notifications —
      // which is safe, but this test is the place a change has to be noticed.
      final decoded = jsonDecode(
        const ReminderNotificationPayload(
          scope: 'baby-1',
          itemId: 'custom_7',
        ).encode(),
      );
      expect(decoded, {'b': 'baby-1', 'i': 'custom_7'});
    });
  });
}
