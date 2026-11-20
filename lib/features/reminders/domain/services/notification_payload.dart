import 'dart:convert';

/// What a scheduled notification carries so a tap can answer *which* reminder
/// fired (B15, PLAN-v1.4.0 D-R9).
///
/// Identity is `(scope, itemId)`: the scope the notification was scheduled for
/// (the baby's id, or the `''` profileless sentinel) and the reminder's **stable**
/// id (`vitamine_d`, `custom_7`). Never the OS notification id and never the plan
/// index — those are a derived cache that reshuffles every time the plan changes
/// (the scheduler assigns ids by position), so a tap resolved through them could
/// settle a different reminder than the one on the screen (B15's "Do not", D2/D5).
///
/// The payload is not secret and not durable: it is a hint handed to the OS for a
/// few hours, read back on tap and re-validated against the database before it
/// means anything (a reminder deleted since the notification fired must not create
/// anything). It never leaves the device — there is no transport in this app.
class ReminderNotificationPayload {
  const ReminderNotificationPayload({
    required this.scope,
    required this.itemId,
  });

  /// Decodes a payload string, or `null` when it is absent or not one of ours.
  ///
  /// Tolerant by necessity: the string comes back from the OS, possibly from a
  /// notification scheduled by a previous version of the app (or by none at all —
  /// a bare tap delivers `null`). Every failure is `null`, which the handler reads
  /// as "navigate Home and touch nothing", the safe half of B22.
  static ReminderNotificationPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final scope = decoded['b'];
    final itemId = decoded['i'];
    if (scope is! String || itemId is! String || itemId.isEmpty) return null;
    return ReminderNotificationPayload(scope: scope, itemId: itemId);
  }

  /// The scope this notification was scheduled for — `''` = the profileless
  /// (legacy, pre-profile) scope, exactly as `reminder_settings` stores it.
  final String scope;

  /// The stable reminder id (`vitamine_d`, `eye_cleaning`, `custom_7`).
  final String itemId;

  /// The same scope as the rest of the data layer wants it: `null` for the
  /// profileless sentinel, since `babyId: null` is what every repository method
  /// maps to `''` — and the other direction is where a `''` would end up written
  /// as a literal baby id.
  String? get scopeOrNull => scope.isEmpty ? null : scope;

  /// `toString` for the log line only. Deliberately no `==`/`hashCode`: the lint
  /// `avoid_equals_and_hash_code_on_mutable_classes` cannot see that this class is
  /// immutable (only its fields are `final`), and adding `@immutable` would import
  /// a framework package into `domain/`, which `check_architecture.py` forbids. The
  /// scheduler compares the encoded **strings**, so nothing here needs equality.
  @override
  String toString() => 'ReminderNotificationPayload($scope, $itemId)';

  /// The form handed to the OS at schedule time.
  ///
  /// Short keys because the payload rides in the notification's intent on Android
  /// and in the `userInfo` on iOS: `b` = scope, `i` = item id.
  String encode() => jsonEncode(<String, String>{'b': scope, 'i': itemId});
}
