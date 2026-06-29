import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class AesService {
  AesService._();

  static final AesGcm _algorithm = AesGcm.with256bits();

  /// Encrypt message using AES-GCM
  static Future<Map<String, dynamic>> encryptMessage({
    required List<int> aesKey,
    required String message,
  }) async {
    final secretKey = SecretKey(aesKey);

    final nonce = _algorithm.newNonce();

    final secretBox = await _algorithm.encrypt(
      utf8.encode(message),
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      "cipherText": base64Encode(secretBox.cipherText),
      "nonce": base64Encode(secretBox.nonce),
      "mac": base64Encode(secretBox.mac.bytes),
    };
  }

  /// Decrypt message using AES-GCM
  static Future<String> decryptMessage({
    required List<int> aesKey,
    required String cipherText,
    required String nonce,
    required String mac,
  }) async {
    final secretKey = SecretKey(aesKey);

    final secretBox = SecretBox(
      base64Decode(cipherText),
      nonce: base64Decode(nonce),
      mac: Mac(base64Decode(mac)),
    );

    final decrypted = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decrypted);
  }
}