// ignore_for_file: avoid_print
/// Porte de contrôle v1.2.1-rc.2 — un seul curseur par fiche de saisie.
///
/// ## Pourquoi ce fichier existe
///
/// La paire « grossier / précis » (BACKLOG B2) est arrivée dans la v1.2.1 par
/// le widget partagé `QuantityPickerInline` : un seul paramètre, cinq fiches
/// touchées d'un coup — nouvelle prise, édition d'une prise, édition d'une
/// sieste, nouvelle mesure, édition d'une mesure. Ouverte sur un appareil, la
/// fiche posait la question « lequel des deux je fais bouger ? » sans y
/// répondre ; la paire est donc retirée (docs/BACKLOG.md B2).
///
/// Ce fichier est la preuve, visuelle et chiffrée, du retrait : sur chaque
/// surface il vérifie qu'il reste **exactement un** `Slider`, qu'il couvre
/// **toute** la plage (et non une fenêtre recentrée), que les libellés
/// `Grossier` / `Précis` ont disparu, que les boutons +/- sont toujours là,
/// et qu'aucune exception de rendu (overflow `RenderFlex`) n'est levée —
/// l'overflow est silencieux dans les tests d'unités qui remontent leur propre
/// viewport, il ne l'est pas sur un vrai écran.
///
/// Dernier test : le chemin manuel complet — curseur pour viser, +/- pour le
/// quantum, clavier pour la valeur exacte — puis le document exporté, inspecté
/// octet par octet. C'est le même document que le panneau de partage reçoit ;
/// une sauvegarde qui omet une section est une sauvegarde fausse, et rien ne
/// la signale à l'écran.
///
/// ## Lancement
///
/// Les deux plateformes passent par `flutter test` (`flutter drive` lève
/// « Binding is already initialized » sur une cible `integration_test`) :
///
/// ```bash
/// # iOS — simulateur démarré
/// flutter test integration_test/pickers_gate_rc2.dart -d <udid>
/// # Android — AVD Small_Phone, 360×640 dp, la cible la plus étroite
/// flutter test integration_test/pickers_gate_rc2.dart -d emulator-5554
/// ```
///
/// Les PNG sont écrits dans le **Documents** de l'app (`path_provider` — un
/// chemin relatif lève `errno 30` sur iOS) puis sortis du bac à sable :
/// iOS par le chemin hôte du conteneur, Android par
/// `adb exec-out run-as <app> cat .../Documents/gate/08_historique.png`.
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mamadera/core/providers/any_baby_exists_provider.dart';
import 'package:mamadera/core/providers/app_preferences_provider.dart';
import 'package:mamadera/core/providers/database_provider.dart';
import 'package:mamadera/core/providers/encryption_provider.dart';
import 'package:mamadera/core/providers/locale_provider.dart';
import 'package:mamadera/core/services/encryption_service.dart';
import 'package:mamadera/data/local/app_db.dart' hide TrackingEvent;
import 'package:mamadera/features/export/data/repositories/export_repository_impl.dart';
import 'package:mamadera/features/growth/data/repositories/measurement_repository_impl.dart';
import 'package:mamadera/features/growth/domain/entities/measure_kind.dart';
import 'package:mamadera/features/history/presentation/widgets/history_tile.dart';
import 'package:mamadera/features/history/presentation/widgets/measurement_history_tile.dart';
import 'package:mamadera/main.dart';
import 'package:mamadera/shared/domain/entities/tracking_event.dart';
import 'package:path_provider/path_provider.dart';

import 'test_utils.dart';

/// Id du bébé du fixture — nom propre, identique dans chaque locale.
const _babyId = 'baby-gate';

/// Base et chiffrement vivants : la dernière étape relit la base pour produire
/// le document exporté, avec **la même** instance `EncryptionService` que
/// l'app — deux instances chiffrent avec des clés différentes quand le
/// stockage sécurisé n'est pas disponible, et alors tout se lit « illisible ».
AppDatabase? _liveDb;
late EncryptionService _liveEncryption;

/// Fixture : une sieste, une prise au biberon, une couche, un soin, et les
/// trois mesures — de quoi ouvrir les cinq surfaces sans écran vide.
Future<(AppDatabase, EncryptionService)> _seededEnv() async {
  final db = AppDatabase(NativeDatabase.memory());
  final encryption = EncryptionService();
  await encryption.initialize();

  final now = DateTime.now();
  await db.insertBabyProfile(
    BabyProfilesCompanion.insert(
      id: _babyId,
      name: 'Léa',
      birthDate:
          now.subtract(const Duration(days: 87)).millisecondsSinceEpoch,
      isActive: const Value(true),
    ),
  );

  await db.insertEvent(
    TrackingEventsCompanion.insert(
      unit: 'min',
      type: 'dodo',
      timestamp: now.subtract(const Duration(hours: 3)),
      duration: const Value(95),
      quantity: const Value(95),
      babyId: const Value(_babyId),
    ),
  );
  await db.insertEvent(
    TrackingEventsCompanion.insert(
      unit: 'ml',
      type: 'miam',
      subtype: const Value('artificial'),
      timestamp: now.subtract(const Duration(hours: 4)),
      quantity: const Value(110),
      babyId: const Value(_babyId),
    ),
  );
  await db.insertEvent(
    TrackingEventsCompanion.insert(
      unit: 'ml',
      type: 'caca',
      timestamp: now.subtract(const Duration(hours: 5)),
      wasteType: const Value('pipi'),
      color: const Value('jaune_clair'),
      babyId: const Value(_babyId),
    ),
  );
  await db.insertEvent(
    TrackingEventsCompanion.insert(
      unit: 'ml',
      type: 'sante',
      subtype: const Value('nettoyage_nez'),
      timestamp: now.subtract(const Duration(hours: 6)),
      babyId: const Value(_babyId),
    ),
  );

  // Par le dépôt, jamais par un insert brut : `value` et `notes` sont
  // chiffrés, et une ligne en clair se lit « illisible » à l'écran.
  final measurements = MeasurementRepositoryImpl(
    database: db,
    encryption: encryption,
  );
  Future<void> measure(
    MeasureKind kind,
    double value,
    Duration ago,
  ) =>
      measurements.add(
        babyId: _babyId,
        kind: kind,
        value: value,
        recordedAt: now.subtract(ago),
      );

  await measure(MeasureKind.poids, 6120, const Duration(days: 3));
  await measure(MeasureKind.taille, 60.5, const Duration(days: 10));
  await measure(MeasureKind.temperature, 37.2, const Duration(hours: 20));

  return (db, encryption);
}

/// Pompe l'app réelle sur le fixture, en **français** : les libellés retirés
/// (« Grossier » / « Précis ») sont français, c'est dans cette langue que la
/// soustraction doit se constater.
Future<void> pumpSeededApp(WidgetTester tester) async {
  if (_liveDb != null) {
    await _liveDb!.close();
    _liveDb = null;
  }
  final (db, encryption) = await _seededEnv();
  _liveDb = db;
  _liveEncryption = encryption;

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetsApp.debugAllowBannerOverride = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(() => ConfigurableLocaleNotifier('fr')),
        appPreferencesProvider.overrideWith(AcceptedTermsNotifier.new),
        anyBabyExistsProvider.overrideWith(BabyExistsNotifier.new),
        databaseProvider.overrideWith((ref) async => db),
        encryptionServiceProvider.overrideWith((ref) async => encryption),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Le curseur unique de la surface courante.
Slider _theSlider(WidgetTester tester) =>
    tester.widgetList<Slider>(find.byType(Slider)).single;

/// Un seul curseur, pleine plage, sans légende, ± présents, rien qui casse.
/// Le `print` est la preuve chiffrée reversée dans docs/release-evidence/.
void expectOneFullRangeSlider(String surface, WidgetTester tester) {
  expect(find.byType(Slider), findsOneWidget,
      reason: '$surface : un seul curseur — la paire B2 est retirée');

  for (final caption in ['Grossier', 'Précis', 'Coarse', 'Fine', 'Grueso', 'Fino']) {
    expect(find.text(caption), findsNothing,
        reason: '$surface : la légende « $caption » doit avoir disparu');
  }

  expect(find.byIcon(Icons.add_circle_outline), findsOneWidget,
      reason: "$surface : le stepper ± reste le nudge d'un quantum");
  expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
  expect(tester.takeException(), isNull,
      reason: '$surface : aucun overflow ni exception au rendu');

  final slider = _theSlider(tester);
  print('[GATE] $surface → 1 slider, min=${slider.min} max=${slider.max} '
      'divisions=${slider.divisions} value=${slider.value}');
}

/// Capture : l'app écrit dans **son** répertoire de documents, puis les PNGs
/// sont sortis à la main du bac à sable (simulateur iOS : un chemin de l'hôte ;
/// emulator Android : `adb exec-out run-as`). Deux pièges mesurés ici même :
/// écrire dans un chemin relatif lève `errno 30 Read-only file system` sur
/// iOS, et `flutter drive` sur une cible `integration_test` fait lever
/// `Binding is already initialized to LiveTestWidgetsFlutterBinding` — d'où
/// `path_provider` d'un côté, `flutter test` de l'autre, pas l'un sans
/// l'autre.
Future<void> capture(WidgetTester tester, String name) async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  await binding.convertFlutterSurfaceToImage();
  await tester.pumpAndSettle(const Duration(milliseconds: 400));

  final bytes = await binding.takeScreenshot(name);
  final documents = await getApplicationDocumentsDirectory();
  final dir = io.Directory('${documents.path}/gate');
  await dir.create(recursive: true);
  final file = io.File('${dir.path}/$name.png');
  await file.writeAsBytes(bytes);
  print('[CAPTURE] ✓ ${file.path} (${bytes.length} bytes)');
}

/// Défile la page (drag depuis le bas vers le haut) jusqu'à ce que [tile] soit
/// dans l'arbre, en forçant la construction des tuiles paresseuses au bas de
/// la frise. Indépendant de `scrollUntilVisible` : celui-ci ne défile que si la
/// tuile est absente de l'arbre, et sa résolution de la Scrollable
/// (`tester.element`) lève « No element » sur l'écran Historique — un drag sur
/// des coordonnées brutes défile la Scrollable sans la résoudre. No-op si la
/// tuile est déjà visible (viewport large, iPhone).
Future<void> _scrollReveal(WidgetTester tester, Finder tile) async {
  final size = tester.getSize(find.byType(MaterialApp));
  final from = Offset(size.width / 2, size.height * 0.8);
  for (var i = 0; i < 50 && tile.evaluate().isEmpty; i++) {
    await tester.dragFrom(from, const Offset(0, -220));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }
}

/// Ouvre la première tuile d'événement du type demandé dans la frise unifiée.
Future<void> openEventTile(
    WidgetTester tester, bool Function(TrackingEvent) matches) async {
  final tile =
      find.byWidgetPredicate((w) => w is HistoryTile && matches(w.event));
  // La frise est une liste paresseuse : sur un écran court (Small_Phone), une
  // entrée ancienne est hors viewport donc absente de l'arbre de widgets.
  // On la force à se construire **avant** d'asserter, sinon le `findsWidgets`
  // d'avant défile échoue par absence et non par faute de donnée.
  await _scrollReveal(tester, tile);
  expect(tile, findsWidgets, reason: 'aucune tuile du type demandé en base');
  // Le reveal ne garantit que la construction, pas la visibilité : la tuile
  // peut être dans l'arbre mais hors viewport, et le tap part dans le vide
  // (`warnIfMissed`) — c'est arrivé à la température, au milieu de la frise.
  await tester.ensureVisible(tile.first);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
  await tester.tap(tile.first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Ouvre la feuille d'édition de la mesure de [kind] dans la frise.
Future<void> openMeasurementTile(WidgetTester tester, MeasureKind kind) async {
  final tile = find.byWidgetPredicate((w) =>
      w is MeasurementHistoryTile && w.measurement.kind == kind);
  // Même piège que `openEventTile` : le poids (3 j) et la température (20 h)
  // sont les mesures les plus vieilles, donc au bas de la frise paresseuse —
  // hors viewport sur Small_Phone, présentes sur l'iPhone plus haut.
  await _scrollReveal(tester, tile);
  expect(tile, findsWidgets,
      reason: 'aucune tuile de mesure ${kind.name} en base');
  // `ensureVisible` avant le tap : la tuile construite peut rester hors
  // viewport et le tap rate (voir `openEventTile`).
  await tester.ensureVisible(tile.first);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
  await tester.tap(tile.first);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

bool _isFeeding(TrackingEvent e) => e.map((_) => false,
    feeding: (_) => true,
    sleep: (_) => false,
    diaper: (_) => false,
    health: (_) => false);

bool _isSleep(TrackingEvent e) => e.map((_) => false,
    feeding: (_) => false,
    sleep: (_) => true,
    diaper: (_) => false,
    health: (_) => false);

void main() {
  group('Porte rc.2 — un curseur par saisie', () {
    testWidgets('nouvelle prise (miam)', (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(findByKey(TestKeys.trackMiam));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expectOneFullRangeSlider('prise · nouvelle', tester);
      // Sein par défaut (v1.2.1) : la plage est celle des minutes.
      expect(_theSlider(tester).max, 120, reason: 'tétée en minutes 0–120');
      expect(_theSlider(tester).divisions, 120, reason: 'un cran par minute');

      await capture(tester, '01_prise_nouvelle');
    });

    testWidgets("édition d'une prise depuis l'historique", (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await openEventTile(tester, _isFeeding);

      expectOneFullRangeSlider('prise · édition', tester);
      expect(_theSlider(tester).max, 300, reason: 'biberon 0–300 ml');
      expect(_theSlider(tester).divisions, 30, reason: 'pas de 10 ml');
      expect(find.text('110 ml'), findsWidgets);

      await capture(tester, '02_prise_edition');
    });

    testWidgets("édition d'une sieste depuis l'historique", (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await openEventTile(tester, _isSleep);

      expectOneFullRangeSlider('sieste · édition', tester);
      expect(_theSlider(tester).max, 480, reason: 'durée 0–480 min');
      expect(_theSlider(tester).divisions, 96, reason: 'pas de 5 min');

      await capture(tester, '03_sieste_edition');
    });

    testWidgets('nouvelle mesure de poids', (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('Poids').last);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expectOneFullRangeSlider('poids · nouvelle', tester);
      expect(_theSlider(tester).min, 200);
      expect(_theSlider(tester).max, 20000);
      expect(_theSlider(tester).divisions, 1980,
          reason: "le pas de 10 g reste — c'est la fenêtre fine qui part");

      await capture(tester, '04_poids_nouvelle');
    });

    testWidgets("édition d'une mesure de poids", (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await openMeasurementTile(tester, MeasureKind.poids);

      expectOneFullRangeSlider('poids · édition', tester);
      expect(_theSlider(tester).min, 200);
      expect(_theSlider(tester).max, 20000);

      await capture(tester, '05_poids_edition');
    });

    testWidgets("édition d'une température au dixième", (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await openMeasurementTile(tester, MeasureKind.temperature);

      expectOneFullRangeSlider('température · édition', tester);
      expect(_theSlider(tester).min, 33);
      expect(_theSlider(tester).max, 42);
      expect(_theSlider(tester).divisions, 90,
          reason: 'pas de 0,1 °C sur toute la plage');
      expect(find.text('37,2 °C'), findsWidgets);

      await capture(tester, '06_temperature_edition');
    });

    testWidgets('saisie manuelle puis export : le nombre survit',
        (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.homeTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(findByKey(TestKeys.trackMiam));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Le chemin d'un parent qui enregistre une tétée : le curseur vise,
      // les +/- ajustent le quantum, le clavier fixe la valeur exacte.
      final box = tester.getRect(find.byType(Slider));
      final before = _theSlider(tester).value;
      await tester.dragFrom(box.center - const Offset(30, 0),
          const Offset(90, 0));
      await tester.pumpAndSettle();
      expect(_theSlider(tester).value, greaterThan(before),
          reason: 'le curseur unique doit encore déplacer la valeur');


      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '22');
      await tester.pumpAndSettle();
      expect(find.text('22 min'), findsWidgets);
      await capture(tester, '07_prise_saisie');

      // Diagnostic : le bouton est-il armé ? (sinon le tap ne fait rien et le
      // silence n'est pas un enregistrement.)
      final confirmFinder = find.text('Confirmer');
      expect(confirmFinder, findsOneWidget);
      // La feuille défile : sans `ensureVisible` le tap part dans le vide
      // hors viewport et le bouton, pourtant armé, ne se presse pas — c'est
      // ce qui a fait échouer cette étape trois exécutions durant.
      await tester.ensureVisible(confirmFinder);
      await tester.pumpAndSettle();
      final button = tester.widget<ElevatedButton>(
        find.ancestor(of: confirmFinder, matching: find.byType(ElevatedButton)),
      );
      print('[GATE] confirmer armé=${button.onPressed != null} '
          'quantité affichée=${find.textContaining('min').evaluate().length}');

      await tester.tap(confirmFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      expect(confirmFinder, findsNothing,
          reason: 'la feuille doit se fermer sur enregistrement');

      final rows = await _liveDb!.getAllTrackingEvents();
      print('[GATE] base après enregistrement → '
          '${rows.map((r) => '${r.type}/${r.unit}/${r.quantity}').join(', ')}');

      // Le document exporté, relu ici : c'est le même contenu que l'app
      // confie au panneau de partage, et une section absente ne se signale
      // pas à l'écran.
      final source = await ExportRepositoryImpl(
        database: _liveDb!,
        encryption: _liveEncryption,
      ).buildExportJson();
      // Le document est aussi écrit dans le Documents de l'app : c'est la
      // preuve exportable de ce que le panneau de partage aurait reçu
      // (sorti du bac à sable comme les captures).
      final gateDir =
          io.Directory('${(await getApplicationDocumentsDirectory()).path}/gate');
      await gateDir.create(recursive: true);
      await io.File('${gateDir.path}/export.json').writeAsString(source);
      final doc = jsonDecode(source) as Map<String, dynamic>;
      final events = (doc['trackingEvents'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(doc.containsKey('measurements'), isTrue,
          reason: 'une table exportée sans être listée est une sauvegarde fausse');
      // Preuve lisible dans le journal avant l'assertion : ce que le document
      // contient vraiment, ligne par ligne.
      print('[GATE] export lignes → '
          '${events.map((e) => '${e['type']}/${e['unit']}/${e['quantity']}').join(', ')}');
      expect(
          events.any((e) => e['unit'] == 'min' && (e['quantity'] as num) == 22),
          isTrue,
          reason: 'le 22 tapé au clavier doit être le 22 exporté');
      print('[GATE] export → format ${doc['exportFormatVersion']}, '
          '${events.length} événements, '
          '${(doc['measurements'] as List<dynamic>).length} mesures, '
          '22 min présent');
    });

    testWidgets("frise d'historique : la sieste se lit en « Durée » seule",
        (tester) async {
      await pumpSeededApp(tester);
      await tester.tap(findByKey(TestKeys.historyTab));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // La sieste du fixture porte 95 min dans `quantity` ET `duration`
      // (comme l'app l'écrit en vrai) ; la tuile ne doit les rendre qu'une
      // fois, avec le libellé naturel d'un dodo — et la date de la tuile la
      // plus récente est sur sa propre ligne (pas « 13/10/2026 21:32 » en
      // bloc unique).
      expect(find.text('Durée: 95 min'), findsOneWidget);
      expect(find.text('Quantité: 95 min'), findsNothing);
      expect(find.text('Quantité : 95 min'), findsNothing);

      expect(tester.takeException(), isNull,
          reason: 'aucun overflow ni exception sur la frise (cible étroite)');

      await capture(tester, '08_historique');
    });
  });
}
