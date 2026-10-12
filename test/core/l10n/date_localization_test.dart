import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/l10n/date_localization.dart';
import 'package:mamadera/l10n/app_localizations.dart';
import 'package:mamadera/shared/domain/entities/tracking_enums.dart';
import 'package:mamadera/shared/domain/entities/tracking_type.dart';

/// Helper: pump a MaterialApp with localization and expose BuildContext via callback.
Future<BuildContext> pumpWithContext(WidgetTester tester, Locale locale) async {
  late BuildContext captured;
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        supportedLocales: [locale],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            captured = context;
            return const Scaffold(body: Text('test'));
          },
        ),
      ),
    ),
  );
  await tester.pump();
  // ignore: unnecessary_non_null_assertion
  return captured!;
}

void main() {
  group('formatDate — FR locale', () {
    testWidgets('renvoie format dd/MM/yyyy HH:mm (24h)', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      final date = DateTime(2024, 6, 15, 10, 30);
      expect(formatDate(context, date), '15/06/2024 10:30');
    });

    testWidgets('minuit est formaté correctement', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      final date = DateTime(2024, 1, 1, 0, 0);
      expect(formatDate(context, date), '01/01/2024 00:00');
    });

    testWidgets('heure tardive est formatée en 24h', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      final date = DateTime(2024, 12, 31, 23, 59);
      expect(formatDate(context, date), '31/12/2024 23:59');
    });
  });

  group('formatDate — EN locale', () {
    // Les attentes de ce groupe ont épinglé le bug pendant un cycle
    // (`hh:aa` rendait le marqueur AM/PM à la place des minutes) : elles ne
    // doivent pas être « corrigées » en arrière.
    testWidgets('renvoie format MM/dd/yyyy hh:mm a (12h)', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      final date = DateTime(2024, 6, 15, 10, 30);
      expect(formatDate(context, date), '06/15/2024 10:30 AM');
    });

    testWidgets('après-midi affiche PM avec les minutes', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      final date = DateTime(2024, 6, 15, 14, 30);
      expect(formatDate(context, date), '06/15/2024 02:30 PM');
    });

    testWidgets('minuit affiche AM', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      final date = DateTime(2024, 1, 1, 0, 0);
      expect(formatDate(context, date), '01/01/2024 12:00 AM');
    });

    testWidgets('midi affiche PM', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      final date = DateTime(2024, 7, 4, 12, 0);
      expect(formatDate(context, date), '07/04/2024 12:00 PM');
    });

    testWidgets('les minutes ne disparaissent jamais', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      // 21:04 et 21:59 doivent se distinguer à l'écran : c'est le seul
      // intérêt de la ligne d'un suivi de fièvre.
      expect(formatDate(context, DateTime(2026, 10, 8, 21, 4)),
          '10/08/2026 09:04 PM');
      expect(formatDate(context, DateTime(2026, 10, 8, 21, 59)),
          '10/08/2026 09:59 PM');
    });
  });

  group('formatDate — les trois locales sur une date fixe', () {
    // Un seul horodatage, trois locales, trois sorties épinglées : le motif
    // ne peut plus pourrir dans une seule branche sans casser ce test.
    final date = DateTime(2026, 10, 8, 19, 43);

    testWidgets('fr', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      expect(formatDate(context, date), '08/10/2026 19:43');
    });

    testWidgets('en', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      expect(formatDate(context, date), '10/08/2026 07:43 PM');
    });

    testWidgets('es', (tester) async {
      final context = await pumpWithContext(tester, const Locale('es'));
      expect(formatDate(context, date), '08/10/2026 19:43');
    });
  });

  group('formatDateShort — FR locale', () {
    testWidgets('renvoie format dd/MM/yyyy sans heure', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      final date = DateTime(2024, 6, 15, 10, 30);
      expect(formatDateShort(context, date), '15/06/2024');
    });

    testWidgets('date début d\'année', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      final date = DateTime(2024, 1, 1);
      expect(formatDateShort(context, date), '01/01/2024');
    });
  });

  group('formatDateShort — EN locale', () {
    testWidgets('renvoie format MM/dd/yyyy sans heure', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      final date = DateTime(2024, 6, 15);
      expect(formatDateShort(context, date), '06/15/2024');
    });

    testWidgets('date fin d\'année', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      final date = DateTime(2024, 12, 31);
      expect(formatDateShort(context, date), '12/31/2024');
    });
  });

  group('getHistoryFilterLabel — FR locale', () {
    testWidgets('filterAll → label localisé', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      expect(getHistoryFilterLabel(context, HistoryFilter.all), isNotEmpty);
    });

    testWidgets('filterMiam → localized label', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      expect(
        getHistoryFilterLabel(context, HistoryFilter.miam),
        'Nourriture',
      );
    });

    testWidgets('filterDodo → localized label', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      expect(
        getHistoryFilterLabel(context, HistoryFilter.dodo),
        'Sommeil',
      );
    });

    testWidgets('filterCaca → localized label', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      expect(getHistoryFilterLabel(context, HistoryFilter.caca), 'Couche');
    });

    testWidgets('filterSante → "Santé"', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      expect(
        getHistoryFilterLabel(context, HistoryFilter.sante),
        'Santé',
      );
    });
  });

  group('getHistoryFilterLabel — EN locale', () {
    testWidgets('filterMiam → "Feeding"', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      expect(
        getHistoryFilterLabel(context, HistoryFilter.miam),
        'Feeding',
      );
    });

    testWidgets('filterDodo → "Sleep"', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      expect(getHistoryFilterLabel(context, HistoryFilter.dodo), 'Sleep');
    });

    testWidgets('filterCaca → "Diaper"', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      expect(
        getHistoryFilterLabel(context, HistoryFilter.caca),
        'Diaper',
      );
    });

    testWidgets('filterSante → "Health"', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      expect(getHistoryFilterLabel(context, HistoryFilter.sante), 'Health');
    });
  });

  group('getTrackingTypeLabel — FR locale', () {
    testWidgets('miam → label maison FR', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      expect(getTrackingTypeLabel(context, TrackingType.miam), 'Nourriture');
    });

    testWidgets('dodo → Dodo', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      expect(
        getTrackingTypeLabel(context, TrackingType.dodo),
        'Dodo',
      );
    });

    testWidgets('caca → Couche', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      expect(getTrackingTypeLabel(context, TrackingType.caca), 'Couche');
    });

    testWidgets('sante → Santé', (tester) async {
      final context = await pumpWithContext(tester, const Locale('fr'));
      expect(
        getTrackingTypeLabel(context, TrackingType.sante),
        'Santé',
      );
    });
  });

  group('getTrackingTypeLabel — EN locale', () {
    testWidgets('miam → Feeding', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      expect(getTrackingTypeLabel(context, TrackingType.miam), 'Feeding');
    });

    testWidgets('dodo → Sleep', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      expect(
        getTrackingTypeLabel(context, TrackingType.dodo),
        'Sleep',
      );
    });

    testWidgets('caca → Diaper', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      expect(getTrackingTypeLabel(context, TrackingType.caca), 'Diaper');
    });

    testWidgets('sante → Health', (tester) async {
      final context = await pumpWithContext(tester, const Locale('en'));
      expect(
        getTrackingTypeLabel(context, TrackingType.sante),
        'Health',
      );
    });
  });
}
