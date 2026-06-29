import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/encryption_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/encryption_service.dart';
import 'core/theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'l10n/app_localizations.dart';

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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final locale = localeState.when(
      data: (pref) => ui.Locale(pref.languageCode),
      loading: () => null,
      error: (_, __) => null,
    );

    final themeNotifier = ref.read(themeProvider.notifier);
    final themeMode = ref.watch(themeProvider).when(
          data: (pref) => themeNotifier.resolveThemeMode(),
          loading: () => ThemeMode.system,
          error: (_, __) => ThemeMode.system,
        );

    return MaterialApp(
      title: 'Mamadera',
      locale: locale,
      supportedLocales: const [ui.Locale('fr'), ui.Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}

