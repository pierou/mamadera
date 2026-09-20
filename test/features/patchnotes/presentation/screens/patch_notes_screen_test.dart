// ignore_for_file: lines_longer_than_80_chars
// Patch notes screen rendering tests.
//
// The patch notes assets are authored in markdown (`### Section`, `- item`),
// exactly like the terms assets. The screen must therefore never print that
// markup: a heading renders as a section title without the check icon, a bullet
// renders as a check-marked row with its marker stripped, inline formatting is
// resolved, and an empty line renders nothing at all.
//
// The shipped-asset assertions below read the JSON from disk rather than
// hard-coding release wording, so they keep guarding the same invariant when the
// 1.2.0 notes land. This is the missing net: the bug shipped unnoticed in 1.0.0
// and 1.0.1 because only the dialog wrapper had a test, never this screen.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamadera/core/theme.dart';
import 'package:mamadera/features/patchnotes/data/patch_notes_repository.dart';
import 'package:mamadera/features/patchnotes/presentation/providers/patch_notes_repository_provider.dart';
import 'package:mamadera/features/patchnotes/presentation/screens/patch_notes_screen.dart';
import 'package:mamadera/l10n/app_localizations.dart';

const _delegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Repository serving a controlled document, so the assertions below do not
/// depend on the wording of any particular release.
class _FakePatchNotesRepository implements PatchNotesRepository {
  const _FakePatchNotesRepository(this.document);

  final Map<String, dynamic> document;

  @override
  Future<Map<String, dynamic>> loadPatchNotes(String locale) async => document;
}

/// A document exercising every shape the assets actually contain: two headings,
/// an inline-bold bullet, a plain bullet, and the trailing empty entry.
const _markdownDocument = <String, dynamic>{
  '9.9.9': <String, dynamic>{
    'releaseDate': '2099-01-01',
    'title': 'Notes de test',
    'items': <String>[
      '### Nouvelles fonctionnalités',
      '- **Ajout** d\'un rappel',
      '- Suivi simple',
      '',
      '### Corrections',
      '- Correction d\'un bug',
      '',
    ],
  },
};

/// Items of the latest version of a shipped asset, read from disk.
///
/// From disk and not through the repository: `rootBundle.loadString` awaited
/// inside a `testWidgets` body never resolves under the fake async binding (it
/// only completes while frames are pumped), which hung this suite.
List<String> shippedItems(String languageCode) {
  final raw = File('assets/patch_notes/$languageCode.json').readAsStringSync();
  final notes = Map<String, dynamic>.from(jsonDecode(raw) as Map);
  final latest = notes[notes.keys.last] as Map;
  return (latest['items'] as List).cast<String>();
}

void main() {
  /// Every string the screen currently renders.
  List<String> rendered(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .toList();

  int checkIcons(WidgetTester tester) =>
      tester.widgetList<Icon>(find.byIcon(Icons.check_circle_outline)).length;

  /// Pumps the screen with [repository], or with the real asset-backed provider
  /// when null. A tall viewport keeps the sheet from overflowing (see the
  /// skipped onboarding case in the home screen tests).
  ///
  /// Pumps until a check-marked row is on screen, on a positive condition on
  /// purpose: keying on "no spinner" raced under suite load and let assertions
  /// run against a still-loading tree. No `pumpAndSettle` either — the loading
  /// `CircularProgressIndicator` animates forever, so it never settles.
  Future<void> pump(
    WidgetTester tester, {
    PatchNotesRepository? repository,
    Locale locale = const Locale('fr'),
  }) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (repository != null)
            patchNotesRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('fr'), Locale('en'), Locale('es')],
          localizationsDelegates: _delegates,
          theme: AppTheme.theme,
          home: const PatchNotesScreen(),
        ),
      ),
    );

    // Le dépôt factice résout à la microtask suivante : deux frames suffisent.
    // Pas de `pumpAndSettle` : le bandeau de chargement anime sans fin et
    // n'attendrait jamais son retour au calme.
    await tester.pump();
    await tester.pump();
  }

  /// One check icon per bullet — none on a heading, none on an empty line.
  void expectIconsMatchBullets(WidgetTester tester, String languageCode) {
    final bullets = shippedItems(languageCode)
        .where((item) => item.trim().isNotEmpty && !item.startsWith('#'))
        .length;

    expect(
      checkIcons(tester),
      equals(bullets),
      reason: '$languageCode: one check icon per bullet, none per heading '
          'or empty line',
    );
  }

  /// No rendered text may keep markdown markup.
  void expectNoMarkup(WidgetTester tester) {
    final texts = rendered(tester);
    expect(texts.where((text) => text.contains('###')), isEmpty,
        reason: 'a "### " heading marker must never reach the screen');
    expect(
      texts.where((text) => text.startsWith('- ') || text.startsWith('* ')),
      isEmpty,
      reason: 'a "- " bullet marker must never reach the screen',
    );
  }

  group('PatchNotesScreen — markdown never reaches the screen', () {
    testWidgets('no rendered text keeps a heading marker', (tester) async {
      await pump(tester, repository: _FakePatchNotesRepository(_markdownDocument));
      expect(rendered(tester).where((text) => text.contains('#')), isEmpty);
    });

    testWidgets('no rendered text keeps a bullet marker', (tester) async {
      await pump(tester, repository: _FakePatchNotesRepository(_markdownDocument));
      expect(
        rendered(tester).where(
          (text) => text.startsWith('- ') || text.startsWith('* '),
        ),
        isEmpty,
      );
    });

    testWidgets('inline bold is resolved, not printed', (tester) async {
      await pump(tester, repository: _FakePatchNotesRepository(_markdownDocument));
      expect(rendered(tester).where((text) => text.contains('**')), isEmpty);
      expect(find.text('Ajout d\'un rappel'), findsOneWidget);
    });

    testWidgets('headings render as section titles without a check icon',
        (tester) async {
      await pump(tester, repository: _FakePatchNotesRepository(_markdownDocument));
      expect(find.text('Nouvelles fonctionnalités'), findsOneWidget);
      expect(find.text('Corrections'), findsOneWidget);
      // Three bullets in the document => three icons; two headings and two empty
      // lines add none.
      expect(checkIcons(tester), 3);
    });

    testWidgets('an empty entry renders no row at all', (tester) async {
      await pump(tester, repository: _FakePatchNotesRepository(_markdownDocument));
      expect(
        rendered(tester).where((text) => text.trim().isEmpty),
        isEmpty,
        reason: 'a "" entry in items[] must not produce a check-marked row',
      );
    });
  });

  /// Notes d'une langue, lues depuis le fichier livré puis servies par un
  /// dépôt factice.
  ///
  /// Le verrou de non-régression porte bien sur le contenu publié — lecture du
  /// fichier, pas d'une copie recopiée dans ce test ; seule la lecture d'asset
  /// est court-circuitée. Charger le vrai asset dans un arbre de widgets n'est
  /// pas fiable ici : `rootBundle` ne répond plus au-delà de la troisième
  /// instantiation de `PatchNotesScreen` dans un même fichier de tests, et
  /// `tester.runAsync` se bat avec le ticker du spinner — les deux observés à
  /// l'écriture de ce fichier. Ce qui était cassé est le rendu ; c'est le
  /// rendu qui est verrouillé.
  PatchNotesRepository shippedAsset(String languageCode) =>
      _FakePatchNotesRepository({
        '9.9.9': <String, dynamic>{
          'releaseDate': '2099-01-01',
          'title': 'Notes de test',
          'items': shippedItems(languageCode),
        },
      });

  group('PatchNotesScreen — shipped assets (regression lock)', () {
    testWidgets('fr notes contain no raw markdown', (tester) async {
      await pump(tester, repository: shippedAsset('fr'), locale: const Locale('fr'));
      expectNoMarkup(tester);
      expect(find.text('Nouvelles fonctionnalités'), findsOneWidget);
    });

    testWidgets('en notes contain no raw markdown', (tester) async {
      await pump(tester, repository: shippedAsset('en'), locale: const Locale('en'));
      expectNoMarkup(tester);
      expect(find.text('New Features'), findsOneWidget);
    });

    testWidgets('es notes contain no raw markdown', (tester) async {
      await pump(tester, repository: shippedAsset('es'), locale: const Locale('es'));
      expectNoMarkup(tester);
      expect(find.text('Nuevas funcionalidades'), findsOneWidget);
    });

    testWidgets('fr notes check one row per bullet', (tester) async {
      await pump(tester, repository: shippedAsset('fr'), locale: const Locale('fr'));
      expectIconsMatchBullets(tester, 'fr');
    });

    testWidgets('en notes check one row per bullet', (tester) async {
      await pump(tester, repository: shippedAsset('en'), locale: const Locale('en'));
      expectIconsMatchBullets(tester, 'en');
    });

    testWidgets('es notes check one row per bullet', (tester) async {
      await pump(tester, repository: shippedAsset('es'), locale: const Locale('es'));
      expectIconsMatchBullets(tester, 'es');
    });
  });
}
