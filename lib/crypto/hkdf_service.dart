import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class HkdfService {
  HkdfService._();

  static final Hkdf _hkdf = Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 32, // AES-256 key size
  );

  /// Convert shared secret into AES encryption key
  static Future<List<int>> deriveAesKey({
    required List<int> sharedSecret,
    String info = 'keyvault-chat',
  }) async {
    final secretKey = SecretKey(sharedSecret);

    final derivedKey = await _hkdf.deriveKey(
      secretKey: secretKey,
      info: utf8.encode(info),
      nonce: [], // optional salt (can be empty for now)
    );

    return await derivedKey.extractBytes();
  }
}


