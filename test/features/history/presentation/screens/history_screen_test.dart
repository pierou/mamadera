import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/features/history/domain/repositories/history_repository.dart';
import 'package:mamadera/features/history/presentation/providers/history_notifier.dart';
import 'package:mamadera/features/history/presentation/providers/history_repository_provider.dart';
import 'package:mamadera/features/history/presentation/screens/history_screen.dart';
import 'package:mamadera/features/history/presentation/widgets/measurement_history_tile.dart';
import 'package:mamadera/features/growth/domain/entities/growth_measurement.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/features/growth/domain/repositories/measurement_repository.dart';
import 'package:mamadera/features/growth/presentation/providers/measurement_providers.dart';
import 'package:mamadera/features/history/presentation/widgets/history_tile.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/quantity_unit.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'history_screen_test.mocks.dart';

// Test locale notifier that returns French locale for consistent string assertions
class _TestLocaleNotifier extends LocaleNotifier {
  Locale? get current =>
      const Locale('fr'); // not overriding, just a test helper property
}

@GenerateNiceMocks([MockSpec<HistoryRepository>()])
void main() {
  late MockHistoryRepository mockRepository;

  // Synthetic fixtures (not constant because DateTime.utc is not constant).
  // Using recent dates to avoid date picker errors (firstDate = now - 2 years).
  final testEvents = [
    FeedingEvent(
      unit: QuantityUnit.ml,
      id: 1,
      timestamp: DateTime.utc(2025, 6, 15, 8, 0),
      subtype: FeedingSubtype.natural,
    ),
    SleepEvent(
      unit: QuantityUnit.min,
      id: 2,
      timestamp: DateTime.utc(2025, 6, 15, 9, 30),
      duration: 60,
    ),
  ];

  setUp(() {
    mockRepository = MockHistoryRepository();
    // Default stubs for the two read methods used by HistoryScreen
    when(mockRepository.getAllEventsOrdered())
        .thenAnswer((_) async => testEvents);
    when(mockRepository.getEventsByType(TrackingType.miam))
        .thenAnswer((_) async => [testEvents.first]);
    when(mockRepository.getEventsByType(TrackingType.sante))
        .thenAnswer((_) async => []);
    when(mockRepository.getEventsByType(TrackingType.caca))
        .thenAnswer((_) async => []);
    when(mockRepository.getEventsByType(TrackingType.dodo))
        .thenAnswer((_) async => [testEvents.last]);

    // Stubs for _showEditDialog mutation calls (unstubbed NiceMocks return null/0)
    when(mockRepository.updateEvent(
            id: anyNamed('id'), event: anyNamed('event')))
        .thenAnswer((_) async => true);
    when(mockRepository.deleteEvent(any)).thenAnswer((_) async => true);
  });

  group('HistoryScreen', () {
    testWidgets('renders AppBar with title "Historique"', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      expect(find.text('Historique'), findsOneWidget);
    });

    testWidgets('displays all filter chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      // Filter chips for all 5 HistoryFilter values
      expect(find.byType(FilterChip), findsNWidgets(5));
    });

    testWidgets('displays event list when data is loaded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      // Should show ListView with events
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('displays empty state when no events', (tester) async {
      when(mockRepository.getAllEventsOrdered()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      expect(find.text('Aucun événement'), findsOneWidget);
    });

    testWidgets('displays loading indicator while data is loading',
        (tester) async {
      // Override to return a Future that never completes initially
      late Completer<List<TrackingEvent>> completer;
      when(mockRepository.getAllEventsOrdered()).thenAnswer((_) {
        completer = Completer();
        return completer.future;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      );

      // First pump — still loading
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future and pump again
      completer.complete(testEvents);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays error message when loading fails', (tester) async {
      final testError = Exception('database connection failed');
      when(mockRepository.getAllEventsOrdered()).thenThrow(testError);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      expect(find.textContaining('Erreur'), findsWidgets);
    });

    testWidgets('displays HistoryTile widgets for each event', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      // 2 events → the date (line 1, shared) and each hour (line 2).
      // must be present. The date and time are now available on two [platforms/sources].
      // lines (v1.2.1: the English date format was causing the minutes to overflow onto the next line).
      // (only one line on the smallest target).
      expect(find.text('15/06/2025'), findsNWidgets(2));
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('09:30'), findsOneWidget);
      expect(find.text('15/06/2025 08:00'), findsNothing);
    });

    testWidgets('tapping filter chip changes selected filter', (tester) async {
      when(mockRepository.getEventsByType(TrackingType.miam))
          .thenAnswer((_) async => [testEvents.first]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      // Tap on the second filter chip (first is "all" which is already selected)
      final chips = find.byType(FilterChip);
      expect(chips, findsNWidgets(5));

      // Tap the 'miam' filter chip (second one after 'Tous')
      await tester.tap(chips.at(1));
      await tester.pumpAndSettle();

      // The miam chip should now be selected
      final firstChip = tester.widget<FilterChip>(chips.at(0));
      expect(firstChip.selected, isFalse);
    });

    testWidgets('tapping HistoryTile opens edit dialog bottom sheet',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      // Tap the first event tile to trigger _showEditDialog (line 131)
      final tiles = find.byType(HistoryTile);
      expect(tiles, findsNWidgets(2));
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // EditEventDialog should be visible inside the bottom sheet
      expect(find.text('Modifier l\'événement'), findsOneWidget);
    });

    testWidgets('_showEditDialog handles UpdateResult from dialog',
        (tester) async {
      // Increase viewport to accommodate taller edit dialog with subtype selector
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      // Tap tile to open dialog
      final tiles = find.byType(HistoryTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Tap Save button → returns UpdateResult
      final saveButton = find.text('Enregistrer');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify updateEvent was called on the repository
      verify(mockRepository.updateEvent(
        id: anyNamed('id'),
        event: anyNamed('event'),
      )).called(1);
    });

    testWidgets('_showEditDialog handles DeleteResult from dialog',
        (tester) async {
      // Increase viewport to accommodate taller edit dialog with subtype selector
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      // Tap tile to open dialog
      final tiles = find.byType(HistoryTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Tap Supprimer button → opens confirmation dialog
      // Scroll down to make the delete button visible
      var deleteButton = find.widgetWithText(TextButton, 'Supprimer');
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();

      expect(deleteButton,
          findsOneWidget); // only the edit form's button initially
      await tester.tapAt(tester.getTopLeft(deleteButton));
      await tester.pumpAndSettle();

      // Confirm deletion in AlertDialog (FilledButton now visible)
      final alertButton = find.byType(FilledButton);
      expect(alertButton, findsOneWidget);
      await tester.tapAt(tester.getTopLeft(alertButton));
      await tester.pumpAndSettle();

      // Verify deleteEvent was called on the repository
      verify(mockRepository.deleteEvent(1)).called(1);
    });

    testWidgets('_showEditDialog handles null result (dismiss without action)',
        (tester) async {
      // Increase viewport to accommodate taller edit dialog with subtype selector
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 900);
      await tester.pump();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider
                .overrideWith((ref) async => _FakeMeasurementRepository()),
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
            localeProvider.overrideWith(_TestLocaleNotifier.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            home: const HistoryScreen(),
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

      // Tap tile to open dialog
      final tiles = find.byType(HistoryTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Dismiss bottom sheet by tapping on the ModalBarrier at a coordinate
      // above the dialog content to avoid gesture passthrough to interactive widgets.
      expect(find.byType(ModalBarrier), findsNWidgets(2));
      await tester.tapAt(const Offset(400, 100));
      await tester.pumpAndSettle();

      // Verify no mutation methods were called on the repository
      verifyNever(mockRepository.updateEvent(
        id: anyNamed('id'),
        event: anyNamed('event'),
      ));
      verifyNever(mockRepository.deleteEvent(any));
    });

    group('Frise unifiée — mesures', () {
      /// Weight of 6180 grams recorded at 8:30 AM – between the 8:00 AM meal.
      /// (testEvents[0]) et le sommeil de 09:30 (testEvents[1]).
      final weight = GrowthMeasurement(
        id: 42,
        kind: MeasureKind.poids,
        unit: 'g',
        recordedAt: DateTime.utc(2025, 6, 15, 8, 30),
        value: 6180,
      );

      testWidgets(
          'une mesure apparaît sous « Tout », triée par horodatage, formatée',
          (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              measurementRepositoryProvider.overrideWith(
                (ref) async => _FakeMeasurementRepository(rows: [weight]),
              ),
              historyRepositoryProvider.overrideWith(
                (_) async => mockRepository,
              ),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              supportedLocales: const [Locale('fr')],
              home: const HistoryScreen(),
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

        // The measurement is determined by its own tile, with a standardized format.
        // (6180 g > 1000 → kg, using a French-style decimal separator).
        expect(find.byType(MeasurementHistoryTile), findsOneWidget);
        expect(find.text('Poids'), findsOneWidget);
        expect(find.text('6,18 kg'), findsOneWidget);

        // Tri desc. : sommeil (09:30) > poids (08:30) > repas (08:00).
        expect(find.byType(HistoryTile), findsNWidgets(2));
        final weightY =
            tester.getCenter(find.byType(MeasurementHistoryTile)).dy;
        expect(
          tester.getCenter(find.byType(HistoryTile).first).dy,
          lessThan(weightY),
        );
        expect(
          tester.getCenter(find.byType(HistoryTile).last).dy,
          greaterThan(weightY),
        );
      });

      testWidgets('aucune mesure sous un filtre de type', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              measurementRepositoryProvider.overrideWith(
                (ref) async => _FakeMeasurementRepository(rows: [weight]),
              ),
              historyRepositoryProvider.overrideWith(
                (_) async => mockRepository,
              ),
              selectedFilterProvider.overrideWith(() => _MiamFilterNotifier()),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              supportedLocales: const [Locale('fr')],
              home: const HistoryScreen(),
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

        expect(find.byType(MeasurementHistoryTile), findsNothing);
        expect(find.byType(HistoryTile), findsOneWidget);
      });
    });
  });
}

/// Set a pre-selected filter to "yum" – this prevents the need to simulate a tap.
/// on the chip to test the exclusion of certain features.
class _MiamFilterNotifier extends SelectedFilterNotifier {
  @override
  HistoryFilter build() => HistoryFilter.miam;
}

/// Fake without a basis: the historical data provider reads the measurement repository.
/// even when using the "all" filter; in testing, the actual factory would be waiting for...
/// channels (base, path_provider) that never respond, and the screen would remain stuck.
/// It can spin indefinitely.
class _FakeMeasurementRepository implements MeasurementRepository {
  _FakeMeasurementRepository({this.rows = const []});

  final List<GrowthMeasurement> rows;

  @override
  Future<void> add({
    required String? babyId,
    required MeasureKind kind,
    required double value,
    required DateTime recordedAt,
    String? notes,
  }) async {}

  @override
  Future<GrowthMeasurement?> latestOfKind(
          String? babyId, MeasureKind kind) async =>
      null;

  @override
  Future<List<GrowthMeasurement>> allForBaby(String? babyId,
          {MeasureKind? kind}) async =>
      (kind == null ? rows : rows.where((m) => m.kind == kind).toList());

  @override
  Future<void> update(GrowthMeasurement measurement) async {}

  @override
  Future<bool> deleteById(int id) async => false;
}
