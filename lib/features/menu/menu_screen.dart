import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations_extension.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final currentLocale = localeAsync.when(
      data: (pref) => pref.languageCode,
      loading: () => 'fr',
      error: (_, __) => 'fr',
    );

    final themeNotifier = ref.read(themeProvider.notifier);
    final currentMode = ref.watch(themeProvider).when(
          data: (pref) => pref.mode,
          loading: () => 'system',
          error: (_, __) => 'system',
        );

    return Scaffold(
      appBar: AppBar(title: Text(context.l.menuTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language Section
              Text(
                context.l.languageSectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildLanguageTile(context, ref, 'fr', currentLocale, context.l.languageFrench),
              _buildLanguageTile(context, ref, 'en', currentLocale, context.l.languageEnglish),

              // Theme Section
              const SizedBox(height: 24),
              Text(
                context.l.themeSectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildThemeTile(context, themeNotifier, 'system', currentMode, Icons.brightness_auto_outlined, Icons.brightness_1, context.l.themeSystem),
              _buildThemeTile(context, themeNotifier, 'light', currentMode, Icons.light_mode_outlined, Icons.light_mode, context.l.themeLight),
              _buildThemeTile(context, themeNotifier, 'dark', currentMode, Icons.dark_mode_outlined, Icons.dark_mode, context.l.themeDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    WidgetRef ref,
    String code,
    String currentCode,
    String label,
  ) {
    final isSelected = code == currentCode;
    return ListTile(
      leading: Icon(isSelected ? Icons.language : Icons.language_outlined),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.greenAccent)
          : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(code);
      },
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    ThemeNotifier themeNotifier,
    String mode,
    String currentMode,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = mode == currentMode;
    return ListTile(
      leading: Icon(isSelected ? filledIcon : outlinedIcon),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.greenAccent)
          : null,
      onTap: () {
        themeNotifier.setMode(mode);
      },
    );
  }
}
