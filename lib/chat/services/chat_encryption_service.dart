import 'package:keyvault/crypto/aes_service.dart';
import 'package:keyvault/crypto/crypto_service.dart';
import 'package:keyvault/crypto/hkdf_service.dart';
import 'package:keyvault/chat/models/chat_message_model.dart';

class ChatEncryptionService {
  ChatEncryptionService._();

  static final Map<String, List<int>> _aesKeyCache = {};

  /// Derive (or retrieve cached) AES key for a session.
  /// Requires the sessionId and the peer's public key (from TrustedContact).
  static Future<List<int>> _getAesKey({
    required String sessionId,
    required String peerPublicKey,
  }) async {
    if (_aesKeyCache.containsKey(sessionId)) {
      return _aesKeyCache[sessionId]!;
    }

    final sharedSecret = await CryptoService.deriveSharedSecret(
      sessionId: sessionId,
      peerPublicKey: peerPublicKey,
    );

    final aesKey = await HkdfService.deriveAesKey(
      sharedSecret: sharedSecret,
      info: 'keyvault-chat',
    );

    _aesKeyCache[sessionId] = aesKey;
    return aesKey;
  }

  static void clearCache({String? sessionId}) {
    if (sessionId != null) {
      _aesKeyCache.remove(sessionId);
    } else {
      _aesKeyCache.clear();
    }
  }

  /// Encrypt a plaintext message and return a [ChatMessageModel].
  static Future<ChatMessageModel> encryptMessage({
    required String sessionId,
    required String from,
    required String to,
    required String message,
    required String peerPublicKey,
  }) async {
    final aesKey = await _getAesKey(
      sessionId: sessionId,
      peerPublicKey: peerPublicKey,
    );

    final result = await AesService.encryptMessage(
      aesKey: aesKey,
      message: message,
    );
    return ChatMessageModel(
      messageId: DateTime.now().microsecondsSinceEpoch.toString(),

      from: from,
      to: to,
      sessionId: sessionId,

      cipherText: result['cipherText'] as String,
      nonce: result['nonce'] as String,
      mac: result['mac'] as String,
      plainText: message,

      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: 'sent',
    );
  }

  /// Decrypt a [ChatMessageModel] and return the plaintext.
  static Future<String> decryptMessage({
    required ChatMessageModel message,
    required String peerPublicKey,
  }) async {
    final aesKey = await _getAesKey(
      sessionId: message.sessionId,
      peerPublicKey: peerPublicKey,
    );

    return AesService.decryptMessage(
      aesKey: aesKey,
      cipherText: message.cipherText,
      nonce: message.nonce,
      mac: message.mac,
    );
  }
}
