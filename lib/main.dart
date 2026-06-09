import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/encryption_provider.dart';
import 'core/services/encryption_service.dart';
import 'data/local/database.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  // Assure que les bindings natifs sont initialisés avant Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise la clé de chiffrement (flutter_secure_storage)
  final encryption = EncryptionService();
  await encryption.initialize();
  // Migre les notes en clair vers le format chiffré (si première exécution)
  try {
    final migratedCount = await DatabaseService.runMigration(encryption);
    if (migratedCount > 0) {
      debugPrint('🔐 Migration: $migratedCount note(s) re-chiffrée(s).');
    }
  } catch (e) {
    // La migration peut échouer si la table n'existe pas encore.
    // Ce n'est pas bloquant : les nouvelles notes seront chiffrées à l'insertion.
    debugPrint('⚠️ Migration ignorée: $e');
  }

  runApp(ProviderScope(
    overrides: [
      encryptionServiceProvider.overrideWithValue(encryption),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mamadera',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}
