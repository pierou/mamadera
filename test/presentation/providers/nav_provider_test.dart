import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/features/home/presentation/providers/nav_provider.dart';

void main() {
  group('NavIndexNotifier', () {
    test('état initial = 0', () {
      final container = ProviderContainer();
      expect(container.read(navIndexProvider), 0);
      container.dispose();
    });

    test('setIndex() change l\'état correctement', () {
      final container = ProviderContainer();

      container.read(navIndexProvider.notifier).setIndex(1);
      expect(container.read(navIndexProvider), 1);

      container.read(navIndexProvider.notifier).setIndex(2);
      expect(container.read(navIndexProvider), 2);

      container.read(navIndexProvider.notifier).setIndex(0);
      expect(container.read(navIndexProvider), 0);

      container.dispose();
    });

    test('setIndex() accepte des valeurs négatives sans crash', () {
      final container = ProviderContainer();

      container.read(navIndexProvider.notifier).setIndex(-1);
      expect(container.read(navIndexProvider), -1);

      container.dispose();
    });

    test('setIndex() peut être appelé plusieurs fois rapidement', () {
      final container = ProviderContainer();
      final notifier = container.read(navIndexProvider.notifier);

      for (var i = 0; i < 10; i++) {
        notifier.setIndex(i);
      }

      expect(container.read(navIndexProvider), 9);
      container.dispose();
    });
  });
}
