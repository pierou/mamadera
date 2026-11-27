import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';
import 'package:mamadera/features/baby/presentation/providers/baby_profile_providers.dart';
import 'package:mamadera/features/baby/presentation/widgets/baby_picker_sheet.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';

/// A profile store in memory: `switchProfile` has to move the selection for these
/// tests to mean anything, which a stubbed provider could not show.
class _FakeBabyProfiles implements BabyProfileRepository {
  _FakeBabyProfiles({required this.profiles, this.activeId});

  final List<BabyProfile> profiles;
  String? activeId;

  int setActiveCalls = 0;

  @override
  Future<List<BabyProfile>> getAllProfiles() async => List.of(profiles);

  @override
  Future<BabyProfile?> getActiveProfile() async =>
      profiles.where((p) => p.id == activeId).firstOrNull;

  @override
  Future<void> setActiveProfile(String id) async {
    setActiveCalls++;
    activeId = id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeBabyProfiles: ${invocation.memberName}');
}

final _anna = BabyProfile(
  id: 'anna-id',
  name: 'Anna',
  birthDate: DateTime(2026, 3, 12),
);
final _blue = BabyProfile(
  id: 'blue-id',
  name: 'Bleu',
  birthDate: DateTime(2026, 7, 1),
  isActive: false,
);

void main() {
  late _FakeBabyProfiles store;

  Future<void> openSheet(WidgetTester tester,
      {required String? activeId}) async {
    store = _FakeBabyProfiles(
      profiles: [_anna, _blue],
      activeId: activeId,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          babyProfileRepositoryProvider.overrideWith((ref) async => store),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.theme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showBabyPickerSheet(context, ref),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  group('BabyPickerSheet (B9)', () {
    testWidgets('lists every child, the active one checked', (tester) async {
      await openSheet(tester, activeId: _anna.id);

      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Bleu'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget,
          reason: 'one tick, on the selected child');
      expect(find.text('Ajouter un bébé'), findsOneWidget);
    });

    testWidgets('tapping another child selects them and closes the sheet',
        (tester) async {
      await openSheet(tester, activeId: _anna.id);

      await tester.tap(find.text('Bleu'));
      await tester.pumpAndSettle();

      expect(store.setActiveCalls, 1);
      expect(store.activeId, _blue.id);
      expect(find.text('Ajouter un bébé'), findsNothing,
          reason: 'the switch is the end of the interaction');
    });

    testWidgets('tapping the already-selected child writes nothing',
        (tester) async {
      // `switchProfile` deactivates every profile and rebuilds the dependent tree;
      // a tap on the child already selected must not pay that cost.
      await openSheet(tester, activeId: _anna.id);

      await tester.tap(find.text('Anna'));
      await tester.pumpAndSettle();

      expect(store.setActiveCalls, 0);
    });

    testWidgets('the add row closes the sheet and opens the shared dialog',
        (tester) async {
      // The row exists so the top entry point is complete — a family adding its
      // second child should not have to find the menu first. The dialog is the
      // Menu's own (`showAddBabyDialog`), so the duplicate-name rule stays in one
      // place.
      await openSheet(tester, activeId: _anna.id);

      await tester.tap(find.text('Ajouter un bébé'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Nom du bébé'), findsOneWidget);
    });
  });
}
