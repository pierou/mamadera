import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/active_baby_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/encryption_provider.dart';
import '../../data/repositories/measurement_repository_impl.dart';
import '../../domain/entities/growth_measurement.dart';
import '../../domain/repositories/measurement_repository.dart';

/// Provider for the measurements repository implementation.
///
/// Exposé sous l'interface domain [MeasurementRepository] pour que la
/// présentation dépende de l'abstraction (et que les tests surchargent un fake).
final measurementRepositoryProvider = FutureProvider<MeasurementRepository>((ref) async {
  final encryption = await ref.read(encryptionServiceProvider.future);
  final database = await ref.watch(databaseProvider.future);
  return MeasurementRepositoryImpl(database: database, encryption: encryption);
});

/// Historique des mesures du bébé actif, le plus récent en premier.
///
/// Keep-alive comme le `reminderNotifierProvider` : watche
/// [activeBabyProvider] pour re-évaluer à chaque changement de bébé, et les
/// boutons d'accueil comme l'écran croissance affichent toujours ceux du
/// bébé sélectionné.
final measurementNotifierProvider =
    AsyncNotifierProvider<MeasurementNotifier, List<GrowthMeasurement>>(
  MeasurementNotifier.new,
);

class MeasurementNotifier extends AsyncNotifier<List<GrowthMeasurement>> {
  @override
  Future<List<GrowthMeasurement>> build() async {
    // Réactivité au changement de bébé (même schéma que le notifieur de rappels).
    ref.watch(activeBabyProvider);
    return _load();
  }

  Future<List<GrowthMeasurement>> _load() async {
    final repository = await ref.read(measurementRepositoryProvider.future);
    if (!ref.mounted) return const [];
    // `null` = lignes sans profil (suivi avant création du profil) : elles
    // restent lisibles, jamais mélangées à celles d'un autre bébé.
    final babyId = ref.read(activeBabyProvider).value?.id;
    return repository.allForBaby(babyId);
  }

  /// Re-lit la liste après une écriture (sauvegarde dans la feuille).
  Future<void> refresh() async {
    final result = await AsyncValue.guard(_load);
    if (ref.mounted) state = result;
  }
}
