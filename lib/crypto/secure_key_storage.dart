import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyStorage {
  SecureKeyStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  static Future<void> saveHasTrustedContact() async {
    await _storage.write(key: 'has_trusted_contact', value: 'true');
  }

  static Future<bool> hasTrustedContact() async {
    final value = await _storage.read(key: 'has_trusted_contact');
    return value == 'true';
  }

  static Future<void> savePrivateKey({
    required String sessionId,
    required String privateKey,
  }) async {
    await _storage.write(key: 'private_key_$sessionId', value: privateKey);
  }

  static Future<void> savePublicKey({
    required String sessionId,
    required String publicKey,
  }) async {
    await _storage.write(key: 'public_key_$sessionId', value: publicKey);
  }

  static Future<String?> getPrivateKey({required String sessionId}) async {
    return await _storage.read(key: 'private_key_$sessionId');
  }

  static Future<String?> getPublicKey({required String sessionId}) async {
    return await _storage.read(key: 'public_key_$sessionId');
  }

  static Future<bool> hasPrivateKey({required String sessionId}) async {
    return await _storage.containsKey(key: 'private_key_$sessionId');
  }

  static Future<void> deletePrivateKey({required String sessionId}) async {
    await _storage.delete(key: 'private_key_$sessionId');
  }

  static Future<void> deletePublicKey({required String sessionId}) async {
    await _storage.delete(key: 'public_key_$sessionId');
  }
}
