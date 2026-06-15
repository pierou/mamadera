import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/services/encryption_migration.dart';
import '../../core/services/encryption_service.dart';
import 'app_db.dart';

/// Crée la connexion LazyDatabase vers le fichier SQLite local.
Future<LazyDatabase> _createConnection() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File('${dbFolder.path}/mamadera.db');

  return LazyDatabase(() => NativeDatabase.createInBackground(file));
}

/// Factory : crée une instance [AppDatabase] prête à l'emploi.
/// Utilisée par le Riverpod provider et les tests (pas de singleton).
Future<AppDatabase> createAppDatabase() async {
    final connection = await _createConnection();
    return AppDatabase(connection);
  }

/// Lance la migration des notes en clair vers les notes chiffrées.
/// Retourne le nombre de notes migrées.
Future<int> runEncryptionMigration(
  AppDatabase db,
  EncryptionService encryption,
) async {
  final migration = EncryptionMigration(db, encryption);
  return migration.migratePlaintextNotes();
}

