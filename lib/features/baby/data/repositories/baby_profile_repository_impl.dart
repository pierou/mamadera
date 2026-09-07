// Alias for drift-generated row types (distinct from domain entities)
import 'package:drift/drift.dart' hide Column;
import 'package:logger/logger.dart';

import '../../../../data/local/app_db.dart' as db_app;
import '../../../../shared/domain/entities/baby_profile.dart';
import '../../domain/repositories/baby_profile_repository.dart';

/// Concrete implementation of [BabyProfileRepository] using Drift.
class BabyProfileRepositoryImpl implements BabyProfileRepository {
  const BabyProfileRepositoryImpl({required this.database});

  final db_app.AppDatabase database;

  static final Logger _logger = Logger();

  @override
  Future<List<BabyProfile>> getAllProfiles() async {
    try {
      final rows = await database.getAllBabyProfiles();
      return rows.map(_toDomain).toList();
    } catch (e, stack) {
      _logger.e('getAllProfiles error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<BabyProfile?> getActiveProfile() async {
    try {
      final row = await database.getActiveBabyProfile();
      if (row == null) return null;
      _logger.d('Found active profile: ${row.name}');
      return _toDomain(row);
    } catch (e, stack) {
      _logger.e('getActiveProfile error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<String> insertProfile(BabyProfile profile) async {
    try {
      final companion = db_app.BabyProfilesCompanion(
        id: Value(profile.id),
        name: Value(profile.name),
        birthDate: Value(profile.birthDate.millisecondsSinceEpoch),
        isActive: Value(profile.isActive),
      );
      await database.insertBabyProfile(companion);
      _logger.d('Inserted baby profile: ${profile.name}');
      return profile.id;
    } catch (e, stack) {
      _logger.e('insertProfile error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<BabyProfile?> updateProfile(String id, {String? name, DateTime? birthDate}) async {
    try {
      final maps = <db_app.BabyProfilesCompanion>[
        if (name != null) db_app.BabyProfilesCompanion(name: Value(name)),
        if (birthDate != null) db_app.BabyProfilesCompanion(birthDate: Value(birthDate.millisecondsSinceEpoch)),
      ];

      for (final companion in maps) {
        await database.updateBabyProfile(id, companion);
      }
      _logger.d('Updated baby profile: $id');

      // Fetch the updated row to return a fresh domain entity.
      final profiles = await getAllProfiles();
      return profiles.firstWhere((p) => p.id == id, orElse: () => throw Exception('Profile not found after update'));
    } catch (e, stack) {
      _logger.e('updateProfile error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<bool> deleteProfile(String id) async {
    try {
      // Les événements du bébé et la ligne de profil partent dans une seule
      // transaction : le schéma n'a ni clé étrangère ni cascade, donc une
      // erreur entre les deux DELETE laisserait soit des événements orphelins,
      // soit un profil dont les événements ont déjà disparu — alors que la
      // boîte de confirmation promet à l'utilisateur les deux suppressions.
      final deleted = await database.transaction(() async {
        await database.deleteTrackingEventsByBabyId(id);
        return database.deleteBabyProfile(id);
      });
      if (deleted) _logger.d('Deleted baby profile: $id');
      return deleted;
    } catch (e, stack) {
      _logger.e('deleteProfile error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> setActiveProfile(String id) async {
    try {
      // Désactiver tout puis activer l'élu doit être atomique : sans
      // transaction, un échec entre les deux UPDATE laisse l'app sans aucun
      // bébé actif (l'échec précédent laissait la fenêtre ouverte).
      await database.transaction(() async {
        // First deactivate all profiles.
        final all = await getAllProfiles();
        for (final profile in all) {
          if (!profile.isActive) continue;
          await database.updateBabyProfile(
            profile.id,
            const db_app.BabyProfilesCompanion(isActive: Value(false)),
          );
        }

        // Then activate the selected one.
        await database.updateBabyProfile(
          id,
          const db_app.BabyProfilesCompanion(isActive: Value(true)),
        );
      });
      _logger.d('Set active profile to $id');
    } catch (e, stack) {
      _logger.e('setActiveProfile error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Convert a drift-generated row type to the domain entity.
  BabyProfile _toDomain(db_app.BabyProfile row) {
    return BabyProfile(
      id: row.id,
      name: row.name,
      birthDate: DateTime.fromMillisecondsSinceEpoch(row.birthDate),
      isActive: row.isActive,
    );
  }
}
