import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'models/key_pair_model.dart';
import 'secure_key_storage.dart';

class CryptoService {
  CryptoService._();

  static final X25519 _algorithm = X25519();

  /// STEP 1: Generate X25519 key pair
  static Future<KeyPairModel> generateKeyPair({
    required String sessionId,
  }) async {
    // Generate key pair
    final keyPair = await _algorithm.newKeyPair();

    // Extract public key
    final publicKey = await keyPair.extractPublicKey();

    // Extract private key
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    // Encode to Base64
    final publicKeyBase64 = base64Encode(publicKey.bytes);
    final privateKeyBase64 = base64Encode(privateKeyBytes);

    // Store PRIVATE key securely (session-based)
    await SecureKeyStorage.savePrivateKey(
      sessionId: sessionId,
      privateKey: privateKeyBase64,
    );

    // Store PUBLIC key also (for reconstruction later)
    await SecureKeyStorage.savePublicKey(
      sessionId: sessionId,
      publicKey: publicKeyBase64,
    );

    // Return ONLY public key
    return KeyPairModel(
      publicKey: publicKeyBase64,
    );
  }

  /// STEP 2: Derive shared secret (X25519)
  static Future<List<int>> deriveSharedSecret({
    required String sessionId,
    required String peerPublicKey,
  }) async {
    // Load our private key
    final privateKeyBase64 =
        await SecureKeyStorage.getPrivateKey(sessionId: sessionId);

    // Load our public key (IMPORTANT for reconstruction)
    final publicKeyBase64 =
        await SecureKeyStorage.getPublicKey(sessionId: sessionId);

    if (privateKeyBase64 == null || publicKeyBase64 == null) {
      throw Exception('Key pair not found for session: $sessionId');
    }

    // Decode keys
    final privateKeyBytes = base64Decode(privateKeyBase64);
    final publicKeyBytes = base64Decode(publicKeyBase64);

    final peerPublicKeyBytes = base64Decode(peerPublicKey);

    // Rebuild OUR key pair (required by cryptography 2.7.0)
    final keyPair = SimpleKeyPairData(
      privateKeyBytes,
      publicKey: SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.x25519,
      ),
      type: KeyPairType.x25519,
    );

    // Peer public key
    final remotePublicKey = SimplePublicKey(
      peerPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    // X25519 shared secret
    final sharedSecret = await _algorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: remotePublicKey,
    );

    // Return raw bytes (NOT Base64)
    return await sharedSecret.extractBytes();
  }
}