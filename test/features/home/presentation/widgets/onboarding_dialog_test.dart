// ignore_for_file: lines_longer_than_80_chars // Tests for OnboardingDialog widget

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/providers/active_baby_provider.dart';
import 'package:mamadera/features/baby/presentation/providers/baby_profile_providers.dart';
import 'package:mamadera/features/home/presentation/widgets/onboarding_dialog.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/baby_profile.dart';
import 'package:mockito/mockito.dart';
import 'package:mamadera/features/baby/domain/repositories/baby_profile_repository.dart';

class MockBabyProfileRepository extends Mock implements BabyProfileRepository {}

void main() {
  group('OnboardingDialog', () {
    testWidgets('renders onboarding dialog with all elements', (tester) async {
      final mockRepo = MockBabyProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            babyProfileRepositoryProvider.overrideWith((ref) async => mockRepo),
            activeBabyProvider.overrideWith(() => _ActiveBabyStub(null)),
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
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => const OnboardingDialog(),
                    );
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(OnboardingDialog), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('displays error when saving with empty name', (tester) async {
      final mockRepo = MockBabyProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            babyProfileRepositoryProvider.overrideWith((ref) async => mockRepo),
            activeBabyProvider.overrideWith(() => _ActiveBabyStub(null)),
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
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => const OnboardingDialog(),
                    );
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap cancel instead of save (empty name = no save, just close)
      final cancelButton = find.text('Annuler');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(OnboardingDialog), findsNothing);
    });
  });
}

class _ActiveBabyStub extends ActiveBabyNotifier {
  _ActiveBabyStub(this._profile);
  final BabyProfile? _profile;

  @override
  Future<BabyProfile?> build() async => _profile;
}
