import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/menu/presentation/screens/feedback_screen.dart';
import '../../features/menu/presentation/screens/menu_screen.dart';
import '../../features/onboarding/presentation/screens/terms_screen.dart';
import '../../features/onboarding/presentation/widgets/terms_acceptance_dialog.dart';
import '../../features/patchnotes/presentation/widgets/patch_notes_dialog.dart';
import '../core/config/app_config.dart';
import '../core/providers/app_preferences_provider.dart';
import '../core/services/app_preferences_service.dart';
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

/// Initial route shown while launch state is loading.
///
/// On iOS/Android the native splash screen covers this window.
/// On desktop platforms (macOS, Windows, Linux) we show a blank white
/// screen so the user never sees home/history/menu before the redirect.
const _splashInitialLocation = '/_splash';

/// Redirect callback that prevents re-evaluating launch conditions on tab switches.
///
/// Only redirects when on the splash route. Once we navigate away from splash,
/// the redirect never fires again (prevents terms/patch-notes on tab switches).
String? _redirect(BuildContext context, GoRouterState state) {
  // Only evaluate launch conditions when on the splash route.
  // Once we navigate away, never redirect again.
  if (state.matchedLocation != _splashInitialLocation) {
    return null;
  }

  // Read preferences to determine the correct initial route.
  final container = ProviderScope.containerOf(context, listen: false);
  final prefs = container.read(appPreferencesProvider);
  return prefs.when(
    data: (AppPreferences p) {
      if (!p.termsAccepted) return '/terms';
      if (p.appVersion != AppConfig.version && p.patchNotesOptOut == false) return '/patch-notes';
      return AppRoute.home.path;
    },
    loading: () => null, // Stay on splash screen while loading
    error: (_, __) => AppRoute.home.path, // Fallback to home on error
  );
}

/// Router go_router avec ShellRoute pour la bottom navigation.
final GoRouter router = GoRouter(
  initialLocation: _splashInitialLocation,
  debugLogDiagnostics: false,
  redirect: _redirect,
  routes: [
    // Splash stub (shown while launch state loads on desktop platforms)
    // The splash screen watches the provider and navigates when ready.
    GoRoute(
      path: _splashInitialLocation,
      name: 'splash',
      builder: (context, state) => const _SplashScreen(),
    ),
    // Terms route (outside shell, full-screen with accept button)
    GoRoute(
      path: '/terms',
      name: 'terms',
      builder: (context, state) => TermsAcceptanceDialog(
        onAccepted: () => context.go(AppRoute.home.path),
      ),
    ),
    // Terms view route (read-only, for re-viewing from Menu)
    GoRoute(
      path: '/terms-view',
      name: 'terms-view',
      builder: (context, state) => const TermsScreen(),
    ),
    // Patch notes route (outside shell, full-screen)
    GoRoute(
      path: '/patch-notes',
      name: 'patch-notes',
      builder: (context, state) => PatchNotesDialog(
        onDismiss: () => context.go(AppRoute.home.path),
      ),
    ),
    // Feedback route (outside shell)
    GoRoute(
      path: '/feedback',
      name: 'feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoute.home.path,
          name: 'home',
          pageBuilder: (context, state) => const MaterialPage(child: HomeScreen()),
        ),
        GoRoute(
          path: AppRoute.history.path,
          name: 'history',
          pageBuilder: (context, state) => const MaterialPage(child: HistoryScreen()),
        ),
        GoRoute(
          path: AppRoute.menu.path,
          name: 'menu',
          pageBuilder: (context, state) => const MaterialPage(child: MenuScreen()),
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
///
/// Converts to a stateful widget so we can detect tab switches and dismiss
/// any open modal bottom sheets (event creation/editing dialogs) that would
/// otherwise persist across navigation changes.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Tracks the last matched location to detect tab switches in build().
  String? _previousLocation;

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final currentLocation = state.matchedLocation;
    final currentIndex = _routeIndexForPath(currentLocation);

    // Detect route change and dismiss any open overlays (dialogs, bottom sheets).
    if (_previousLocation != null && currentLocation != _previousLocation) {
      _previousLocation = currentLocation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final navigator = Navigator.of(context);
        while (navigator.canPop()) {
          navigator.pop();
        }
      });
    }
    _previousLocation ??= currentLocation;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
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

/// Minimal white splash screen shown on desktop platforms while launch state loads.
///
/// On iOS/Android the native splash screen covers this window, but on desktop
/// platforms (macOS, Windows, Linux) we need a placeholder to prevent showing
/// home/history/menu before the redirect callback resolves.
///
/// Watches [appPreferencesProvider] and navigates to the correct route
/// once preferences are loaded. This ensures the redirect works even when
/// the provider resolves asynchronously (e.g., in tests).
class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);

    return prefs.when(
      data: (AppPreferences p) {
        // Navigate to the correct route once preferences are loaded.
        // Use addPostFrameCallback to avoid navigating during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!p.termsAccepted) {
            context.go('/terms');
          } else if (p.appVersion != AppConfig.version && p.patchNotesOptOut == false) {
            context.go('/patch-notes');
          } else {
            context.go(AppRoute.home.path);
          }
        });

        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) {
        // Fallback to home on error.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(AppRoute.home.path);
        });

        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
