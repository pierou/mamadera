import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de chiffrement AES-GCM pour les données sensibles.
/// La clé maître est stockée dans flutter_secure_storage (Keychain iOS / Keystore Android).
class EncryptionService {
  /// Constructeur avec injection optionnelle du stockage sécurisé.
  EncryptionService([FlutterSecureStorage? secureStorage])
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _masterKeyName = 'mamadera_master_key';

  final FlutterSecureStorage _secureStorage;
  Key? _cachedKey;

  /// Initialise ou récupère la clé maître depuis le stockage sécurisé.
  Future<void> initialize() async {
    final existingKeyB64 = await _secureStorage.read(key: _masterKeyName);

    if (existingKeyB64 != null && existingKeyB64.isNotEmpty) {
      _cachedKey = Key.fromBase64(existingKeyB64);
    } else {
      // Génère une nouvelle clé AES-256 aléatoire
      final newKey = Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: _masterKeyName,
        value: newKey.base64,
      );
      _cachedKey = newKey;
    }
  }

  /// Retourne la clé maître. Lance une erreur si non initialisée.
  Key get key {
    if (_cachedKey == null) {
      throw StateError(
        'EncryptionService not initialized. Call initialize() first.',
      );
    }

    return _cachedKey!;
  }

  /// Chiffre une chaîne en AES-GCM. Retourne `iv_base64:ciphertext_base64`.
  String encrypt(String plainText) {
    if (plainText.isEmpty) {
      return '';
    }

    final iv = IV.fromSecureRandom(12); // GCM recommande 12 octets
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Format compact : IV:Ciphertext (tous deux en base64)
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Déchiffre une chaîne format `iv_base64:ciphertext_base64`.
  String? decrypt(String? cipherText) {
    if (cipherText == null || cipherText.isEmpty) {
      return null;
    }

    final parts = cipherText.split(':');
    // Le format attend exactement iv:ciphertext, mais le ciphertext peut contenir ':' dans son base64 ?
    // Non, base64 standard ne contient pas ':'. On split donc en 2 parties max.
    if (parts.length < 2) {
      return null;
    }

    try {
      final iv = IV.fromBase64(parts[0]);
      // Rejoin les parties restantes au cas où (sécurité future)
      final cipherData = parts.sublist(1).join(':');
      final encryptedData = Encrypted.fromBase64(cipherData);
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (_) {
      // Échec silencieux pour éviter les fuites d'information (timing attacks)
      return null;
    }
  }

  /// Vérifie si une valeur est chiffrée (format attendu).
  bool isEncrypted(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }

    final parts = value.split(':');
    // Format minimal : iv_base64:ciphertext_base64
    return parts.length >= 2 && _isValidBase64(parts[0]) && _isValidBase64(parts[1]);
  }

  bool _isValidBase64(String str) {
    try {
      final bytes = base64Decode(str);
      // IV GCM = 12 octets → base64 encode en ~16 chars minimum
      return bytes.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Réinitialise la clé maître (pour changement de mot de passe / reset sécurité).
  Future<void> rotateKey() async {
    await _secureStorage.delete(key: _masterKeyName);
    _cachedKey = null;
    await initialize(); // Génère une nouvelle clé
  }

  /// Supprime complètement la clé maître (logout / désinstallation sécurisée).
  Future<void> destroyKey() async {
    await _secureStorage.delete(key: _masterKeyName);
    _cachedKey = null;
  }
}


