import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/menu/presentation/screens/menu_screen.dart';
import '../l10n/app_localizations.dart';

/// Routes de l'application.
enum AppRoute {
  home('/home'),
  history('/history'),
  menu('/menu');

  const AppRoute(this.path);
  final String path;
}

/// Index de la bottom navigation pour chaque route.
final _routeToIndex = <String, int>{
  AppRoute.home.path: 0,
  AppRoute.history.path: 1,
  AppRoute.menu.path: 2,
};

/// Router go_router avec ShellRoute pour la bottom navigation.
final GoRouter router = GoRouter(
  initialLocation: AppRoute.home.path,
  debugLogDiagnostics: false,
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoute.home.path,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoute.history.path,
          name: 'history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: AppRoute.menu.path,
          name: 'menu',
          builder: (context, state) => const MenuScreen(),
        ),
      ],
    ),
  ],

  /// Error page quand la route n'existe pas.
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Page introuvable',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.error?.toString() ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoute.home.path),
            child: const Text("Retour à l'accueil"),
          ),
        ],
      ),
    ),
  ),
);

/// Shell widget qui affiche la bottom navigation et le contenu de la route.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = GoRouterState.of(context);
    final path = state.matchedLocation;
    final currentIndex = _routeToIndex[path] ?? 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          final route = _routeToPath(index);
          context.go(route);
        },
      ),
    );
  }

  String _routeToPath(int index) {
    switch (index) {
      case 0:
        return AppRoute.home.path;
      case 1:
        return AppRoute.history.path;
      case 2:
        return AppRoute.menu.path;
      default:
        return AppRoute.home.path;
    }
  }
}

/// Bottom navigation widget.
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: l.navHome,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history_outlined),
          activeIcon: const Icon(Icons.history),
          label: l.navHistory,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined),
          activeIcon: const Icon(Icons.settings),
          label: l.navMenu,
        ),
      ],
    );
  }
}
