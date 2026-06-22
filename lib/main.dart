import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/encryption_provider.dart';
import 'core/services/encryption_service.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  // Assure que les bindings natifs sont initialisés avant Flutter
  WidgetsFlutterBinding.ensureInitialized();

  final encryption = EncryptionService();

  // Initialise la clé de chiffrement (flutter_secure_storage)
  await encryption.initialize();
  if (encryption.isUsingMemoryFallback) {
    debugPrint(
      '⚠️ Mode fallback: clé volatile en mémoire (pas de keyring disponible).',
    );
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

