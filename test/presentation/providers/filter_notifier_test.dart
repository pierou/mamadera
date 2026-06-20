// ignore_for_file: cascade_invocations
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/presentation/providers/history_notifier.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('FilterNotifier', () {
    test('état initial = HistoryFilter.all', () {
      final container = ProviderContainer();
      expect(container.read(selectedFilterProvider), HistoryFilter.all);
      container.dispose();
    });

    test('setFilter() change le filtre vers chaque enum valide', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedFilterProvider.notifier);

      for (final filter in HistoryFilter.values) {
        notifier.setFilter(filter);
        expect(container.read(selectedFilterProvider), filter);
      }

      container.dispose();
    });

    test('setFilter() peut être appelé plusieurs fois rapidement', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedFilterProvider.notifier);

      HistoryFilter.values.forEach(notifier.setFilter);
      // Dernier filtre appliqué est le dernier de l'enum.
      expect(
        container.read(selectedFilterProvider),
        HistoryFilter.values.last,
      );

      container.dispose();
    });

    test('setFilter(HistoryFilter.all) réinitialise sur "Tous"', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedFilterProvider.notifier);

      notifier.setFilter(HistoryFilter.miam);
      expect(container.read(selectedFilterProvider), HistoryFilter.miam);

      notifier.setFilter(HistoryFilter.all);
      expect(container.read(selectedFilterProvider), HistoryFilter.all);

      container.dispose();
    });
  });
}

