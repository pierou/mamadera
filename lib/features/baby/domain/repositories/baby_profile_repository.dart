/// Repository interface for baby profile CRUD operations.
///
/// Domain layer — pure Dart, no Flutter dependencies except entity types.
library;

import '../../../../shared/domain/entities/baby_profile.dart';

abstract class BabyProfileRepository {
  /// Return all stored profiles ordered by creation date (newest first).
  Future<List<BabyProfile>> getAllProfiles();

  /// Return the currently active profile, or `null` if no profile exists.
  ///
  /// B31: if profiles exist but none claims active (the state a process
  /// death used to leave behind), the oldest profile is promoted — and the
  /// flag persisted — before this returns, so the invariant "profiles
  /// exist ⇒ exactly one active row" holds after any read.
  Future<BabyProfile?> getActiveProfile();

  /// Insert a new baby profile into persistent storage.
  Future<String> insertProfile(BabyProfile profile);

  /// Update an existing profile's mutable fields.
  ///
  /// Returns the updated profile on success, or `null` if [id] was not found.
  Future<BabyProfile?> updateProfile(String id,
      {String? name, DateTime? birthDate});

  /// Delete a baby profile and, in the same transaction, every tracking event
  /// belonging to it — no event is ever left orphaned behind a deleted baby.
  ///
  /// B31: if the deleted baby was the active one and profiles remain, a
  /// survivor is re-activated **inside that same transaction** (oldest by
  /// birth date, then id) — the old delete-then-switch gap that left
  /// devices with no active profile is closed at the source, on top of the
  /// read-boundary self-heal in [getActiveProfile].
  Future<bool> deleteProfile(String id);

  /// Set a single profile as the active one, atomically deactivating any
  /// previously active profile — the two updates never land separately.
  Future<void> setActiveProfile(String id);
}
