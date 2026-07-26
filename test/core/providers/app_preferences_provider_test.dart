import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/config/app_config.dart';
import 'package:mamadera/core/providers/app_preferences_provider.dart';
import 'package:mamadera/core/services/app_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPreferencesProvider', () {
    late ProviderContainer container;
    late AppPreferencesService mockService;

    setUp(() {
      mockService = AppPreferencesService();
      container = ProviderContainer(
        overrides: [
          appPreferencesServiceProvider.overrideWith((ref) => mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has correct defaults', () async {
      final state = await container.read(appPreferencesProvider.future);
      expect(state.appVersion, AppConfig.version);
      expect(state.termsAccepted, false);
      expect(state.patchNotesOptOut, false);
    });

    test('acceptTerms sets termsAccepted to true', () async {
      await container.read(appPreferencesProvider.notifier).acceptTerms();
      final state = container.read(appPreferencesProvider);

      expect(state.value!.termsAccepted, true);
    });

    test('setPatchNotesOptOut sets patchNotesOptOut', () async {
      await container.read(appPreferencesProvider.notifier).setPatchNotesOptOut(value: true);
      final state = container.read(appPreferencesProvider);

      expect(state.value!.patchNotesOptOut, true);
    });

    test('markPatchNotesSeen sets appVersion to current', () async {
      await container.read(appPreferencesProvider.notifier).markPatchNotesSeen();
      final state = container.read(appPreferencesProvider);

      expect(state.value!.appVersion, AppConfig.version);
    });

    test('multiple operations work correctly', () async {
      await container.read(appPreferencesProvider.notifier).acceptTerms();
      await container.read(appPreferencesProvider.notifier).setPatchNotesOptOut(value: true);
      await container.read(appPreferencesProvider.notifier).markPatchNotesSeen();

      final state = container.read(appPreferencesProvider);
      expect(state.value!.termsAccepted, true);
      expect(state.value!.patchNotesOptOut, true);
      expect(state.value!.appVersion, AppConfig.version);
    });
  });
}
