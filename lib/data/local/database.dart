import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'app_db.dart';

Future<LazyDatabase> _createConnection() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File('${dbFolder.path}/mamadera.db');

  return LazyDatabase(() => NativeDatabase.createInBackground(file));
}

class DatabaseService {

  DatabaseService._internal() {
    _databaseFuture = _initDatabase();
  }

  factory DatabaseService() => _instance;
  static final DatabaseService _instance = DatabaseService._internal();
  late final Future<AppDatabase> _databaseFuture;

  Future<AppDatabase> get database async {
    return _databaseFuture;
  }

  Future<AppDatabase> _initDatabase() async {
    final connection = await _createConnection();
    return AppDatabase(connection);
  }
}
