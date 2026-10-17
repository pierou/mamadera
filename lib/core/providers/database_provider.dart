import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_db.dart';
import '../../data/local/database.dart';

/// Singleton provider for the Drift connection.
/// The database instance is created only once and shared via Riverpod instead of using the static factory pattern.
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return createAppDatabase();
});
