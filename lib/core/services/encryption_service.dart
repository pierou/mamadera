import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Service de chiffrement AES-GCM pour les données sensibles.
/// La clé maître est stockée dans flutter_secure_storage (Keychain iOS / Keystore Android).
/// Sur desktop sans keyring disponible, fallback sur une clé volatile en mémoire.
class EncryptionService {
  /// Constructeur avec injection optionnelle du stockage sécurisé.
  EncryptionService([FlutterSecureStorage? secureStorage])
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _masterKeyName = 'mamadera_master_key';

  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();
  Key? _cachedKey;
  /// True si on utilise le fallback mémoire (pas de keyring disponible).
  bool _usingMemoryFallback = false;

  Future<Key> _generateAndStoreKey() async {
    final newKey = Key.fromSecureRandom(32);
    await _secureStorage.write(key: _masterKeyName, value: newKey.base64);
    _logger.d('Nouvelle clé maître générée et stockée.');
    return newKey;
  }

  void _fallbackToMemoryKey(Object error) {
    _logger.w(
      'Stockage sécurisé indisponible ($error). Fallback: clé volatile en mémoire.',
    );
    final newKey = Key.fromSecureRandom(32);
    _cachedKey = newKey;
    _usingMemoryFallback = true;

    if (kDebugMode) {
      debugPrint(
        '⚠️ CLÉ VOLATILE: les données chiffrées seront perdues au redémarrage.',
      );
    }
  }

  /// Initialise ou récupère la clé maître depuis le stockage sécurisé.
  /// Si le backend natif n'est pas disponible (ex: Linux sans GNOME Keyring),
  /// génère une clé volatile en mémoire et log un avertissement.
  Future<void> initialize() async {
    try {
      final existingKeyB64 = await _secureStorage.read(key: _masterKeyName);

      if (existingKeyB64 != null && existingKeyB64.isNotEmpty) {
        _cachedKey = Key.fromBase64(existingKeyB64);
        _logger.d('Clé maître chargée depuis le stockage sécurisé.');
      } else {
        _cachedKey = await _generateAndStoreKey();
      }
    } catch (e) {
      _fallbackToMemoryKey(e);
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

  /// Retourne true si on utilise le fallback mémoire (pas de persistance).
  bool get isUsingMemoryFallback => _usingMemoryFallback;

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

  /// Parse `iv_base64:ciphertext_base64` → `(IV, Encrypted)` or null.
  ({IV iv, Encrypted encrypted})? _parseCipherText(String cipherText) {
    final parts = cipherText.split(':');
    if (parts.length < 2) return null;

    try {
      final iv = IV.fromBase64(parts[0]);
      final cipherData = parts.sublist(1).join(':');
      final encryptedData = Encrypted.fromBase64(cipherData);
      return (iv: iv, encrypted: encryptedData);
    } catch (_) {
      return null;
    }
  }

  /// Déchiffre une chaîne format `iv_base64:ciphertext_base64`.
  String? decrypt(String? cipherText) {
    if (cipherText == null || cipherText.isEmpty) return null;

    final parsed = _parseCipherText(cipherText);
    if (parsed == null) return null;

    try {
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      return encrypter.decrypt(parsed.encrypted, iv: parsed.iv);
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
    return parts.length >= 2 &&
        _isValidBase64(parts[0]) &&
        _isValidBase64(parts[1]);
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
    if (!_usingMemoryFallback) {
      await _secureStorage.delete(key: _masterKeyName);
    }
    _cachedKey = null;
    await initialize(); // Génère une nouvelle clé
  }

  /// Supprime complètement la clé maître (logout / désinstallation sécurisée).
  Future<void> destroyKey() async {
    if (!_usingMemoryFallback) {
      await _secureStorage.delete(key: _masterKeyName);
    }
    _cachedKey = null;
  }
}
