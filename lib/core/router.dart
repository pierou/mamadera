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

/// Retourne l'index d'une route pour les transitions positionnelles.
int routeIndex(AppRoute route) => <AppRoute, int>{
  AppRoute.home: 0,
  AppRoute.history: 1,
  AppRoute.menu: 2,
}[route]!;

/// Retourne l'index d'une route basée sur son chemin.
int _routeIndexForPath(String path) {
  return <String, int>{
    AppRoute.home.path: 0,
    AppRoute.history.path: 1,
    AppRoute.menu.path: 2,
  }[path] ?? 0;
}

/// Stocke le chemin de la route précédente pour les transitions.
String? _previousPath;

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
          pageBuilder: (context, state) => pageBuilder(AppRoute.home, const HomeScreen(), context, state, previousPath: _previousPath),
        ),
        GoRoute(
          path: AppRoute.history.path,
          name: 'history',
          pageBuilder: (context, state) => pageBuilder(AppRoute.history, const HistoryScreen(), context, state, previousPath: _previousPath),
        ),
        GoRoute(
          path: AppRoute.menu.path,
          name: 'menu',
          pageBuilder: (context, state) => pageBuilder(AppRoute.menu, const MenuScreen(), context, state, previousPath: _previousPath),
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

/// Construit une animation de transition par glissement basée sur l'index de la route.
Widget slideTransitionBuilder({
  required BuildContext context,
  required Animation<double> animation,
  required GoRouterState state,
  required Widget child,
  String? previousPath,
}) {
  final currentIndex = state.matchedLocation == AppRoute.home.path
      ? 0
      : state.matchedLocation == AppRoute.history.path
          ? 1
          : 2;

  // Déterminer la direction en comparant les index de route
  final previousIndex = previousPath != null ? _routeIndexForPath(previousPath) : null;
  final direction = previousIndex != null && previousIndex != currentIndex
      ? (currentIndex - previousIndex).clamp(-1.0, 1.0)
      : 0.0;

  final begin = switch (direction) {
    > 0 => const Offset(1, 0),
    < 0 => const Offset(-1, 0),
    _ => Offset.zero,
  };

  return SlideTransition(
    position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    ),
    child: child,
  );
}

/// Construit un [CustomTransitionPage] avec transition de glissement positionnelle.
CustomTransitionPage<dynamic> pageBuilder(
  AppRoute route,
  Widget child,
  BuildContext context,
  GoRouterState state, {
  String? previousPath,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return slideTransitionBuilder(
        context: context,
        animation: animation,
        state: state,
        child: child,
        previousPath: previousPath,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}

/// Shell widget qui affiche la bottom navigation et le contenu de la route.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = GoRouterState.of(context);
    final path = state.matchedLocation;
    final currentIndex = _routeIndexForPath(path);

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          // Enregistrer le chemin actuel avant la navigation
          _previousPath = path;
          context.go(AppRoute.values[index].path);
        },
      ),
    );
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
