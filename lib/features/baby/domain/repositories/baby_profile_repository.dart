/// Repository interface for baby profile CRUD operations.
///
/// Domain layer — pure Dart, no Flutter dependencies except entity types.
library;

import '../../../../shared/domain/entities/baby_profile.dart';

abstract class BabyProfileRepository {
  /// Return all stored profiles ordered by creation date (newest first).
  Future<List<BabyProfile>> getAllProfiles();

  /// Return the currently active profile, or `null` if none exists.
  Future<BabyProfile?> getActiveProfile();

  /// Insert a new baby profile into persistent storage.
  Future<String> insertProfile(BabyProfile profile);

  /// Update an existing profile's mutable fields.
  ///
  /// Returns the updated profile on success, or `null` if [id] was not found.
  Future<BabyProfile?> updateProfile(String id, {String? name, DateTime? birthDate});

  /// Delete a baby profile (cascade: events linked to this profile remain but become orphaned).
  Future<bool> deleteProfile(String id);

  /// Set a single profile as the active one (deactivates any previously active profile).
  Future<void> setActiveProfile(String id);
}
