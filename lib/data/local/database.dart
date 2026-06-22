import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'app_db.dart';

/// Crée la connexion LazyDatabase vers le fichier SQLite local.
/// Si [directoryPath] est fourni, utilise ce chemin sinon utilise path_provider.
Future<LazyDatabase> _createConnection([String? directoryPath]) async {
  final dbFolder = directoryPath != null
      ? Directory(directoryPath)
      : await getApplicationDocumentsDirectory();
  final file = File('${dbFolder.path}/mamadera.db');

  return LazyDatabase(() => NativeDatabase.createInBackground(file));
}

/// Factory : crée une instance [AppDatabase] prête à l'emploi.
/// Utilisée par le Riverpod provider et les tests (pas de singleton).
/// Si [directoryPath] est fourni, utilise ce chemin sinon utilise path_provider.
Future<AppDatabase> createAppDatabase({String? directoryPath}) async {
    final connection = await _createConnection(directoryPath);
    return AppDatabase(connection);
  }

