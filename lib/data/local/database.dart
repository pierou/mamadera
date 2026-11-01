import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'app_db.dart';

/// Creates a LazyDatabase connection to the local SQLite file.
/// If [directoryPath] is provided, use that path; otherwise, use the path provided by `path_provider`.
Future<LazyDatabase> _createConnection([String? directoryPath]) async {
  final dbFolder = directoryPath != null
      ? Directory(directoryPath)
      : await getApplicationDocumentsDirectory();
  final file = File('${dbFolder.path}/mamadera.db');

  return LazyDatabase(() => NativeDatabase.createInBackground(file));
}

/// Factory: Creates an instance of [AppDatabase] that is ready to use.
/// Used by the Riverpod provider and tests (not a singleton).
/// If [directoryPath] is provided, use that path; otherwise, use the path provided by `path_provider`.
Future<AppDatabase> createAppDatabase({String? directoryPath}) async {
  final connection = await _createConnection(directoryPath);
  return AppDatabase(connection);
}

/// Resets the database by deleting the physical SQLite file.
/// The next call to `createAppDatabase()` will rebuild a fresh database.
/// using the current schema (`AppDatabase.schemaVersion`), through the `onCreate` method.
/// If [directoryPath] is provided, use that path; otherwise, use the path provided by `path_provider`.
Future<void> resetDatabase({String? directoryPath}) async {
  final dbFolder = directoryPath != null
      ? Directory(directoryPath)
      : await getApplicationDocumentsDirectory();
  final file = File('${dbFolder.path}/mamadera.db');

  if (!await file.exists()) {
    return; // No files to delete.
  }

  await file.delete();
}
