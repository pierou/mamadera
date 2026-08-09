import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/encryption_service.dart';

/// Provider singleton pour le service de chiffrement.
///
/// Uses [FutureProvider] to ensure [EncryptionService.initialize()] is called
/// before the service is accessed, avoiding uninitialized state crashes.
final encryptionServiceProvider = FutureProvider<EncryptionService>((ref) async {
  final service = EncryptionService();
  await service.initialize();
  return service;
});
