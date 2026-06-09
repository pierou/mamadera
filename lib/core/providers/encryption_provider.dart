import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/encryption_service.dart';

/// Provider singleton pour le service de chiffrement.
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});
