import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations_extension.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav(
      {required this.currentIndex, required this.onTap, super.key});
  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: theme.scaffoldBackgroundColor,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: context.l.navHome),
        BottomNavigationBarItem(icon: const Icon(Icons.history), label: context.l.navHistory),
        BottomNavigationBarItem(icon: const Icon(Icons.settings), label: context.l.navMenu),
      ],
    );
  }
}
