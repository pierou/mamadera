import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_extension.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../providers/menu_repository_provider.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final currentLanguage = localeAsync.when(
      data: (pref) => pref.languageCode,
      loading: () => 'fr',
      error: (_, __) => 'fr',
    );

    final themeAsync = ref.watch(themeProvider);
    final currentThemeMode = themeAsync.when(
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
              _buildLanguageTile(context, ref, 'fr', currentLanguage, context.l.languageFrench),
              _buildLanguageTile(context, ref, 'en', currentLanguage, context.l.languageEnglish),

              // Theme Section
              const SizedBox(height: 24),
              Text(
                context.l.themeSectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildThemeTile(context, ref, 'system', currentThemeMode, Icons.brightness_auto_outlined, Icons.brightness_1, context.l.themeSystem),
              _buildThemeTile(context, ref, 'light', currentThemeMode, Icons.light_mode_outlined, Icons.light_mode, context.l.themeLight),
              _buildThemeTile(context, ref, 'dark', currentThemeMode, Icons.dark_mode_outlined, Icons.dark_mode, context.l.themeDark),

              // Danger Zone
              const SizedBox(height: 32),
              Text(
                context.l.dangerZoneTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
              ),
              const SizedBox(height: 8),
              _buildResetDatabaseTile(context, ref),
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
        ref.read(menuRepositoryProvider).setLanguage(code);
      },
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    WidgetRef ref,
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
        ref.read(menuRepositoryProvider).setThemeMode(mode);
      },
    );
  }

  Widget _buildResetDatabaseTile(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showResetDatabaseDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _dangerZoneDecoration(),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(child: _resetDatabaseInfo(context)),
            Icon(Icons.chevron_right, color: Colors.red.shade600),
          ],
        ),
      ),
    );
  }

  BoxDecoration _dangerZoneDecoration() => BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      );

  Widget _resetDatabaseInfo(BuildContext context) {
    final titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.red.shade600,
    );
    final descStyle = TextStyle(
      fontSize: 12,
      color: Colors.red.shade700,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.resetDatabaseButton, style: titleStyle),
        const SizedBox(height: 4),
        Text(context.l.resetDatabaseWarningDetail, style: descStyle),
      ],
    );
  }

  Future<void> _showResetDatabaseDialog(BuildContext context, WidgetRef ref) async {
    final confirmTitle = context.l.resetDatabaseConfirm;
    final confirmContent = context.l.resetDatabaseWarningDetail;
    final confirmLabel = context.l.resetDatabaseButton;
    final cancelLabel = context.l.cancel;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(cancelLabel)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: Text(confirmLabel)),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _performReset(context, ref);
    }
  }

  Future<void> _performReset(BuildContext context, WidgetRef ref) async {
    final successLabel = context.l.resetDatabaseSuccess;
    final errorLabel = context.l.resetDatabaseError;
    try {
      await ref.read(menuRepositoryProvider).resetDatabase();
      if (context.mounted) _showSnackBar(context, successLabel, Colors.green);
    } catch (e) {
      if (context.mounted) _showSnackBar(context, errorLabel(e.toString()), Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}
