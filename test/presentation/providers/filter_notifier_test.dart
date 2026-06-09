// ignore_for_file: cascade_invocations
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/history/presentation/providers/history_notifier.dart';

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

      notifier.setFilter('miam');
      expect(container.read(selectedFilterProvider), 'miam');

      notifier.setFilter('dodo');
      expect(container.read(selectedFilterProvider), 'dodo');

      notifier.setFilter('all');
      expect(container.read(selectedFilterProvider), 'all');

      container.dispose();
    });

    test('setFilter() peut recevoir n\'importe quelle chaîne', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedFilterProvider.notifier);

      notifier.setFilter('caca');
      expect(container.read(selectedFilterProvider), 'caca');

      notifier.setFilter('sein');
      expect(container.read(selectedFilterProvider), 'sein');

      notifier.setFilter('biberon');
      expect(container.read(selectedFilterProvider), 'biberon');

      container.dispose();
    });

    test('setFilter() peut être appelé plusieurs fois rapidement', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedFilterProvider.notifier);

      final filtres = ['miam', 'dodo', 'caca', 'sein', 'all'];
      filtres.forEach(notifier.setFilter);

      expect(container.read(selectedFilterProvider), 'all');
      container.dispose();
    });

    test('setFilter() avec chaîne vide fonctionne', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedFilterProvider.notifier);

      notifier.setFilter('');
      expect(container.read(selectedFilterProvider), '');

      container.dispose();
    });
  });
}
