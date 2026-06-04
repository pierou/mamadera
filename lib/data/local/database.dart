import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'app_db.dart';

LazyDatabase _createConnection() {
  return LazyDatabase(
    () => NativeDatabase.createInBackground(File('mamadera.db')),
  );
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late final AppDatabase _database;

  DatabaseService._internal() {
    _database = AppDatabase(_createConnection());
  }

  factory DatabaseService() => _instance;

  AppDatabase get database => _database;
}
