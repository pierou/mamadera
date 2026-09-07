import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/patch_notes_repository.dart';

/// Riverpod provider that exposes a [PatchNotesRepository] instance.
///
/// The repository is stateless (it only reads locale-specific JSON assets),
/// so a plain [Provider] is enough — no database or encryption dependency.
final patchNotesRepositoryProvider = Provider<PatchNotesRepository>(
  (ref) => const PatchNotesRepository(),
);
