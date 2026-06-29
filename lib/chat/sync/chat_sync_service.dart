import 'dart:async';

import 'package:keyvault/chat/models/chat_message_model.dart';
import 'package:keyvault/chat/repositories/chat_repository.dart';
import 'package:keyvault/chat/services/chat_encryption_service.dart';
import 'package:keyvault/chat/storage/local_chat_storage.dart';

class ChatSyncService {
  final LocalChatStorage _localStorage;

  StreamSubscription<List<ChatMessageModel>>? _subscription;

  ChatSyncService({required LocalChatStorage localStorage})
    : _localStorage = localStorage;

  void startSync({required String sessionId, required String peerPublicKey}) {
    stopSync();

    _subscription = ChatRepository.getChat(sessionId).listen((messages) async {
      for (final message in messages) {
        try {
          final existing = await _localStorage.getMessage(message.messageId);

          if (existing != null) continue;

          final plainText = await ChatEncryptionService.decryptMessage(
            message: message,
            peerPublicKey: peerPublicKey,
          );

          await _localStorage.insertOrUpdateMessage(
            message.copyWith(plainText: plainText),
          );
        } catch (_) {}
      }
    }, onError: (_) {});
  }

  void stopSync() {
    _subscription?.cancel();
    _subscription = null;
  }
}
