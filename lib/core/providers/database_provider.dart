import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_db.dart';
import '../../data/local/database.dart';

/// Provider singleton pour la connexion Drift.
/// La DB est créée une seule fois et partagée via Riverpod au lieu du pattern factory statique.
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return createAppDatabase();
});
