// ignore_for_file: lines_longer_than_80_chars // Tests for AppRoute enum and AppShell widget

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mamadera/core/router.dart';
import 'package:mamadera/l10n/app_localizations.dart';

void main() {
  group('AppRoute', () {
    test('home route path is correct', () {
      expect(AppRoute.home.path, '/home');
    });

    test('history route path is correct', () {
      expect(AppRoute.history.path, '/history');
    });

    test('menu route path is correct', () {
      expect(AppRoute.menu.path, '/menu');
    });

    test('home route index is 0', () {
      expect(routeIndex(AppRoute.home), 0);
    });

    test('history route index is 1', () {
      expect(routeIndex(AppRoute.history), 1);
    });

    test('menu route index is 2', () {
      expect(routeIndex(AppRoute.menu), 2);
    });

    test('all routes have unique paths', () {
      final paths = AppRoute.values.map((e) => e.path).toList();
      expect(paths.toSet().length, paths.length);
    });

    test('all routes have unique indices', () {
      final indices = AppRoute.values.map(routeIndex).toList();
      expect(indices.toSet().length, indices.length);
    });

    test('has 3 routes', () {
      expect(AppRoute.values.length, 3);
    });

    test('all routes have non-empty paths starting with /', () {
      for (final route in AppRoute.values) {
        expect(route.path.isNotEmpty && route.path.startsWith('/'), isTrue);
      }
    });

    test('AppRoute.values can be indexed by position', () {
      expect(AppRoute.values[0], AppRoute.home);
      expect(AppRoute.values[1], AppRoute.history);
      expect(AppRoute.values[2], AppRoute.menu);
    });
  });

  group('AppShell', () {
    testWidgets('renders AppShell with bottom navigation bar', (tester) async {
      // Create a test router with simple stub widgets (no Riverpod dependencies)
      final testRouter = GoRouter(
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
                pageBuilder: (context, state) => pageBuilder(AppRoute.home, const _StubHome(), context, state, previousPath: null),
              ),
              GoRoute(
                path: AppRoute.history.path,
                name: 'history',
                pageBuilder: (context, state) => pageBuilder(AppRoute.history, const _StubHome(), context, state, previousPath: null),
              ),
              GoRoute(
                path: AppRoute.menu.path,
                name: 'menu',
                pageBuilder: (context, state) => pageBuilder(AppRoute.menu, const _StubHome(), context, state, previousPath: null),
              ),
            ],
          ),
        ],
        errorBuilder: (context, state) => const _StubHome(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('displays child content by default', (tester) async {
      final testRouter = GoRouter(
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
                pageBuilder: (context, state) => pageBuilder(AppRoute.home, const _StubHome(), context, state, previousPath: null),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The stub home shows "Home Screen" text
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('navigates to different routes updates child', (tester) async {
      final testRouter = GoRouter(
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
                pageBuilder: (context, state) => pageBuilder(AppRoute.home, const _StubHome(), context, state, previousPath: null),
              ),
              GoRoute(
                path: AppRoute.history.path,
                name: 'history',
                pageBuilder: (context, state) => pageBuilder(AppRoute.history, const _StubHistory(), context, state, previousPath: null),
              ),
              GoRoute(
                path: AppRoute.menu.path,
                name: 'menu',
                pageBuilder: (context, state) => pageBuilder(AppRoute.menu, const _StubMenu(), context, state, previousPath: null),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start on home
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.text('History Screen'), findsNothing);

      // Navigate to history
      testRouter.go(AppRoute.history.path);
      await tester.pumpAndSettle();

      expect(find.text('History Screen'), findsOneWidget);
      expect(find.text('Home Screen'), findsNothing);

      // Navigate to menu
      testRouter.go(AppRoute.menu.path);
      await tester.pumpAndSettle();

      expect(find.text('Menu Screen'), findsOneWidget);
    });

    testWidgets('shows error page for unknown route', (tester) async {
      final testRouter = GoRouter(
        initialLocation: '/unknown-route',
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
                pageBuilder: (context, state) => pageBuilder(AppRoute.home, const _StubHome(), context, state, previousPath: null),
              ),
            ],
          ),
        ],
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

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Page introuvable'), findsOneWidget);
      expect(find.text("Retour à l'accueil"), findsOneWidget);
    });

    testWidgets('navigation flow between routes works correctly', (tester) async {
      final testRouter = GoRouter(
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
                pageBuilder: (context, state) => pageBuilder(AppRoute.home, const _StubHome(), context, state, previousPath: null),
              ),
              GoRoute(
                path: AppRoute.history.path,
                name: 'history',
                pageBuilder: (context, state) => pageBuilder(AppRoute.history, const _StubHistory(), context, state, previousPath: null),
              ),
              GoRoute(
                path: AppRoute.menu.path,
                name: 'menu',
                pageBuilder: (context, state) => pageBuilder(AppRoute.menu, const _StubMenu(), context, state, previousPath: null),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start on home
      expect(find.text('Home Screen'), findsOneWidget);

      // Navigate to history
      testRouter.go(AppRoute.history.path);
      await tester.pumpAndSettle();

      expect(find.text('History Screen'), findsOneWidget);
      expect(find.text('Home Screen'), findsNothing);

      // Navigate back to home
      testRouter.go(AppRoute.home.path);
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.text('History Screen'), findsNothing);
    });

    testWidgets('route to index mapping is correct', (tester) async {
      final testRouter = GoRouter(
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
                pageBuilder: (context, state) => pageBuilder(AppRoute.home, const _StubHome(), context, state, previousPath: null),
              ),
              GoRoute(
                path: AppRoute.history.path,
                name: 'history',
                pageBuilder: (context, state) => pageBuilder(AppRoute.history, const _StubHistory(), context, state, previousPath: null),
              ),
              GoRoute(
                path: AppRoute.menu.path,
                name: 'menu',
                pageBuilder: (context, state) => pageBuilder(AppRoute.menu, const _StubMenu(), context, state, previousPath: null),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Home is index 0
      var nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar).first);
      expect(nav.currentIndex, 0);

      // Navigate to history (index 1)
      testRouter.go(AppRoute.history.path);
      await tester.pumpAndSettle();

      nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar).first);
      expect(nav.currentIndex, 1);

      // Navigate to menu (index 2)
      testRouter.go(AppRoute.menu.path);
      await tester.pumpAndSettle();

      nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar).first);
      expect(nav.currentIndex, 2);
    });
  });
}

/// Simple stub widgets for testing router without Riverpod dependencies.
class _StubHome extends StatelessWidget {
  const _StubHome();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home Screen')));
}

class _StubHistory extends StatelessWidget {
  const _StubHistory();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('History Screen')));
}

class _StubMenu extends StatelessWidget {
  const _StubMenu();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Menu Screen')));
}
