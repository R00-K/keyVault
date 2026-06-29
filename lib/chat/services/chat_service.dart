import 'package:keyvault/chat/models/chat_message_model.dart';
import 'package:keyvault/chat/repositories/chat_repository.dart';
import 'package:keyvault/chat/services/chat_encryption_service.dart';
import 'package:keyvault/chat/storage/local_chat_storage.dart';
import 'package:keyvault/chat/sync/chat_sync_service.dart';

class ChatService {
  static LocalChatStorage? _localStorage;
  static ChatSyncService? _syncService;

  static void initialize({
    required LocalChatStorage localStorage,
    required ChatSyncService syncService,
  }) {
    _localStorage = localStorage;
    _syncService = syncService;
  }

  static LocalChatStorage get _storage {
    if (_localStorage == null) {
      throw StateError('ChatService not initialized');
    }
    return _localStorage!;
  }

  static ChatSyncService get _sync {
    if (_syncService == null) {
      throw StateError('ChatService not initialized');
    }
    return _syncService!;
  }

  static Future<void> sendMessage({
    required String sessionId,
    required String from,
    required String to,
    required String message,
    required String peerPublicKey,
  }) async {
    final encrypted = await ChatEncryptionService.encryptMessage(
      sessionId: sessionId,
      from: from,
      to: to,
      message: message,
      peerPublicKey: peerPublicKey,
    );

    await _storage.saveMessage(encrypted);

    try {
      await ChatRepository.sendMessage(encrypted);
    } catch (_) {}
  }

  static Stream<List<ChatMessageModel>> getMessagesStream(String sessionId) {
    return _storage.watchMessages(sessionId);
  }

  static void startSync({
    required String sessionId,
    required String peerPublicKey,
  }) {
    _sync.startSync(sessionId: sessionId, peerPublicKey: peerPublicKey);
  }

  static void stopSync() {
    _sync.stopSync();
  }

  static Future<void> clearChat(String sessionId) async {
    await _storage.clearChat(sessionId);
  }
}
