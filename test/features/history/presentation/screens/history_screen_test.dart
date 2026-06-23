import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/domain/repositories/history_repository.dart';
import 'package:mamadera/features/history/presentation/providers/history_repository_provider.dart';
import 'package:mamadera/features/history/presentation/screens/history_screen.dart';
import 'package:mamadera/features/history/presentation/widgets/history_tile.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'history_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<HistoryRepository>()])
void main() {
  late MockHistoryRepository mockRepository;

  // Fixtures synthétiques (non-const car DateTime.utc n'est pas const)
  final testEvents = [
    TrackingEvent(
      id: 1,
      type: TrackingType.miam,
      timestamp: DateTime.utc(2024, 1, 1, 8, 0),
    ),
    TrackingEvent(
      id: 2,
      type: TrackingType.dodo,
      timestamp: DateTime.utc(2024, 1, 1, 9, 30),
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
    when(mockRepository.updateEvent(id: anyNamed('id'))).thenAnswer((_) async => true);
    when(mockRepository.deleteEvent(any)).thenAnswer((_) async => true);
  });

  group('HistoryScreen', () {
    testWidgets('renders AppBar with title "Historique"', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Historique'), findsOneWidget);
    });

    testWidgets('displays all filter chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
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
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Should show ListView with events
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('displays empty state when no events', (tester) async {
      when(mockRepository.getAllEventsOrdered())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun événement'), findsOneWidget);
    });

    testWidgets('displays loading indicator while data is loading', (tester) async {
      // Override to return a Future that never completes initially
      late Completer<List<TrackingEvent>> completer;
      when(mockRepository.getAllEventsOrdered()).thenAnswer((_) {
        completer = Completer();
        return completer.future;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
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
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur'), findsWidgets);
    });

    testWidgets('displays HistoryTile widgets for each event', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 2 events → at least the formatted time text should be present
      expect(find.text('01/01/2024 08:00'), findsOneWidget);
      expect(find.text('01/01/2024 09:30'), findsOneWidget);
    });

    testWidgets('tapping filter chip changes selected filter', (tester) async {
      when(mockRepository.getEventsByType(TrackingType.miam))
          .thenAnswer((_) async => [testEvents.first]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
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

    testWidgets('tapping HistoryTile opens edit dialog bottom sheet', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
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

    testWidgets('_showEditDialog handles UpdateResult from dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tile to open dialog
      final tiles = find.byType(HistoryTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Tap Enregistrar button → returns UpdateResult
      final saveButton = find.text('Enregistrer');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify updateEvent was called on the repository
      verify(mockRepository.updateEvent(
        id: anyNamed('id'),
        timestamp: anyNamed('timestamp'),
        duration: anyNamed('duration'),
        notes: anyNamed('notes'),
        wasteType: anyNamed('wasteType'),
        pipiColor: anyNamed('pipiColor'),
        cacaColor: anyNamed('cacaColor'),
      )).called(1);
    });

    testWidgets('_showEditDialog handles DeleteResult from dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tile to open dialog
      final tiles = find.byType(HistoryTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Tap Supprimer button → opens confirmation dialog
      var deleteButtons = find.text('Supprimer');
      expect(deleteButtons, findsOneWidget); // only the edit form's button initially
      await tester.tapAt(tester.getTopLeft(deleteButtons));
      await tester.pumpAndSettle();

      // Confirm deletion in AlertDialog (second Supprimer button now visible)
      deleteButtons = find.text('Supprimer');
      expect(deleteButtons, findsNWidgets(2)); // edit form + confirm dialog
      final alertButton = deleteButtons.at(1); // AlertDialog's button is on top
      await tester.tapAt(tester.getTopLeft(alertButton));
      await tester.pumpAndSettle();

      // Verify deleteEvent was called on the repository
      verify(mockRepository.deleteEvent(1)).called(1);
    });

    testWidgets('_showEditDialog handles null result (dismiss without action)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyRepositoryProvider.overrideWith(
              (_) async => mockRepository,
            ),
          ],
          child: const MaterialApp(home: HistoryScreen()),
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
        timestamp: anyNamed('timestamp'),
        duration: anyNamed('duration'),
        notes: anyNamed('notes'),
        wasteType: anyNamed('wasteType'),
        pipiColor: anyNamed('pipiColor'),
        cacaColor: anyNamed('cacaColor'),
      ));
      verifyNever(mockRepository.deleteEvent(any));
    });
  });
}
