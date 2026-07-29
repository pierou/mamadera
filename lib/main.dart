import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'core/providers/encryption_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router.dart';
import 'core/services/encryption_service.dart';
import 'core/services/locale_service.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';

Locale? _resolveLocale(AsyncValue<LocalePreference> localeState) {
  return localeState.when(
    data: (pref) => ui.Locale(pref.languageCode),
    loading: () => null,
    error: (_, __) => null,
  );
}

ThemeMode _resolveThemeMode(WidgetRef ref) {
  final themeNotifier = ref.read(themeProvider.notifier);
  return ref.watch(themeProvider).when(
        data: (pref) => themeNotifier.resolveThemeMode(),
        loading: () => ThemeMode.system,
        error: (_, __) => ThemeMode.system,
      );
}

Future<EncryptionService> _initializeEncryption() async {
  final encryption = EncryptionService();
  await encryption.initialize();
  if (encryption.isUsingMemoryFallback) {
    Logger().w('⚠️ Mode fallback: clé volatile en mémoire (pas de keyring disponible).');
  }
  return encryption;
}

void main() async {
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  final encryption = await _initializeEncryption();
  runApp(
    ProviderScope(
      overrides: [
        encryptionServiceProvider.overrideWith((ref) async => encryption),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = _resolveLocale(ref.watch(localeProvider));
    final themeMode = _resolveThemeMode(ref);

    return MaterialApp.router(
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
      routerConfig: router,
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FlutterNativeSplash.remove();
        });

        // Wrap all screens with SafeArea to respect iOS notches and home indicators.
        return SafeArea(
          top: false, // Allow app bar/status bar area to extend to top
          bottom: true,
          left: true,
          right: true,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

