// ignore_for_file: cascade_invocations
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/presentation/providers/history_notifier.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';

void main() {
  group('FilterNotifier', () {
    test('état initial = "all"', () {
      final container = ProviderContainer();
      expect(container.read(selectedFilterProvider), 'all');
      container.dispose();
    });

    test('setFilter() change le filtre', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedFilterProvider.notifier);

      notifier.setFilter('miam' as HistoryFilter);
      expect(container.read(selectedFilterProvider), 'miam');

      notifier.setFilter('dodo' as HistoryFilter);
      expect(container.read(selectedFilterProvider), 'dodo');

      notifier.setFilter('all' as HistoryFilter);
      expect(container.read(selectedFilterProvider), 'all');

      container.dispose();
    });

    test('setFilter() peut recevoir n\'importe quelle chaîne', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedFilterProvider.notifier);

      notifier.setFilter('caca' as HistoryFilter);
      expect(container.read(selectedFilterProvider), 'caca');

      notifier.setFilter('sein' as HistoryFilter);
      expect(container.read(selectedFilterProvider), 'sein');

      notifier.setFilter('biberon' as HistoryFilter);
      expect(container.read(selectedFilterProvider), 'biberon');

      container.dispose();
    });

    test('setFilter() peut être appelé plusieurs fois rapidement', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedFilterProvider.notifier);

      final filtres = ['miam', 'dodo', 'caca', 'sein', 'all'];
      filtres.forEach(notifier.setFilter as void Function(String element));

      expect(container.read(selectedFilterProvider), 'all');
      container.dispose();
    });

    test('setFilter() avec chaîne vide fonctionne', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedFilterProvider.notifier);

      notifier.setFilter('' as HistoryFilter);
      expect(container.read(selectedFilterProvider), '');

      container.dispose();
    });
  });
}
