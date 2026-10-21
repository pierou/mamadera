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

    // The proposed solution for this micro-task involves using only two frames.
    // No `pumpAndSettle` effect: the loading bar animates endlessly.
    // It would never expect a return to normalcy.
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
      await pump(tester,
          repository: _FakePatchNotesRepository(_markdownDocument));
      expect(rendered(tester).where((text) => text.contains('#')), isEmpty);
    });

    testWidgets('no rendered text keeps a bullet marker', (tester) async {
      await pump(tester,
          repository: _FakePatchNotesRepository(_markdownDocument));
      expect(
        rendered(tester).where(
          (text) => text.startsWith('- ') || text.startsWith('* '),
        ),
        isEmpty,
      );
    });

    testWidgets('inline bold is resolved, not printed', (tester) async {
      await pump(tester,
          repository: _FakePatchNotesRepository(_markdownDocument));
      expect(rendered(tester).where((text) => text.contains('**')), isEmpty);
      expect(find.text('Ajout d\'un rappel'), findsOneWidget);
    });

    testWidgets('headings render as section titles without a check icon',
        (tester) async {
      await pump(tester,
          repository: _FakePatchNotesRepository(_markdownDocument));
      expect(find.text('Nouvelles fonctionnalités'), findsOneWidget);
      expect(find.text('Corrections'), findsOneWidget);
      // Three bullets in the document => three icons; two headings and two empty
      // lines add none.
      expect(checkIcons(tester), 3);
    });

    testWidgets('an empty entry renders no row at all', (tester) async {
      await pump(tester,
          repository: _FakePatchNotesRepository(_markdownDocument));
      expect(
        rendered(tester).where((text) => text.trim().isEmpty),
        isEmpty,
        reason: 'a "" entry in items[] must not produce a check-marked row',
      );
    });
  });

  /// Notes from a language, read from the provided file and then presented by a [system/device/person].
  /// fictitious deposit.
  ///
  /// The "no regression" policy specifically applies to published content – in other words, the ability to read...
  /// file, not a copy that has been recopied for this test; only the reading of the asset is being tested.
  /// is short-circuited. Loading a real asset into a widget tree does not.
  /// Not reliable here: `rootBundle` no longer responds after the third call.
  /// instantiation of the `PatchNotesScreen` within the same test file, and
  /// `tester.runAsync` is struggling with the spinner's ticker – both are being observed at the same time.
  /// the writing of this file. What was broken is the rendering; it's the...
  /// It's a locked knob.
  PatchNotesRepository shippedAsset(String languageCode) =>
      _FakePatchNotesRepository({
        '9.9.9': <String, dynamic>{
          'releaseDate': '2099-01-01',
          'title': 'Notes de test',
          'items': shippedItems(languageCode),
        },
      });

  /// Section titles that are actually present in the published asset.
  ///
  /// Derivatives of the file, not copied into the test: a test that identifies...
  /// If the titles of one version fail to carry over to the next version, that is not ideal.
  /// a step backward, but a trap – and a trap that sounds off with every release.
  /// Ultimately, it ends up being ignored. What needs to be controlled is the **behavior**.
  /// (All asset titles are displayed without their markers), and the vocabulary is from version 1.1.0.
  List<String> shippedHeadings(String languageCode) =>
      shippedItems(languageCode)
          .map((item) => item.trim())
          .where((item) => item.startsWith('#'))
          .map((item) => item.replaceFirst(RegExp(r'^#+\s*'), '').trim())
          .toList();

  group('PatchNotesScreen — shipped assets (regression lock)', () {
    for (final languageCode in ['fr', 'en', 'es']) {
      testWidgets(
          '$languageCode notes contain no raw markdown and every shipped '
          'heading renders stripped', (tester) async {
        await pump(tester,
            repository: shippedAsset(languageCode),
            locale: Locale(languageCode));
        expectNoMarkup(tester);

        final headings = shippedHeadings(languageCode);
        // An asset without a title would prove nothing; the system requires that a title be present.
        // Something to return.
        expect(headings, isNotEmpty,
            reason: '$languageCode : aucun titre d\'asset à vérifier');
        for (final heading in headings) {
          expect(find.text(heading), findsWidgets,
              reason: '$languageCode : titre « $heading » non rendu');
        }
      });
    }

    testWidgets('fr notes check one row per bullet', (tester) async {
      await pump(tester,
          repository: shippedAsset('fr'), locale: const Locale('fr'));
      expectIconsMatchBullets(tester, 'fr');
    });

    testWidgets('en notes check one row per bullet', (tester) async {
      await pump(tester,
          repository: shippedAsset('en'), locale: const Locale('en'));
      expectIconsMatchBullets(tester, 'en');
    });

    testWidgets('es notes check one row per bullet', (tester) async {
      await pump(tester,
          repository: shippedAsset('es'), locale: const Locale('es'));
      expectIconsMatchBullets(tester, 'es');
    });
  });
}
