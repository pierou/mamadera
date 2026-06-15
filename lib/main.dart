import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/encryption_provider.dart';
import 'core/services/encryption_service.dart';
import 'data/local/database.dart' as db_factory;
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  // Assure que les bindings natifs sont initialisés avant Flutter
  WidgetsFlutterBinding.ensureInitialized();

  final encryption = EncryptionService();

  try {
    // Initialise la clé de chiffrement (flutter_secure_storage)
    await encryption.initialize();
    if (encryption.isUsingMemoryFallback) {
      debugPrint(
        '⚠️ Mode fallback: clé volatile en mémoire (pas de keyring disponible).',
      );
    }

    // Migre les notes en clair vers le format chiffré (si première exécution).
    // On crée une DB temporaire uniquement pour la migration, puis on la ferme.
    final db = await db_factory.createAppDatabase();
    final migratedCount = await db_factory.runEncryptionMigration(db, encryption);
    if (migratedCount > 0) {
      debugPrint('🔐 Migration: $migratedCount note(s) re-chiffrée(s).');
    }
  } catch (e, stack) {
    // La migration peut échouer si la table n'existe pas encore.
    // Ce n'est pas bloquant : les nouvelles notes seront chiffrées à l'insertion.
    debugPrint('⚠️ Erreur init: $e');
    debugPrint(stack.toString());
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

