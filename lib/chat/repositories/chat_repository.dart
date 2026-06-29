import 'package:keyvault/infra/api/services/firestore_service.dart';
import 'package:keyvault/chat/models/chat_message_model.dart';

class ChatRepository {
  ChatRepository._();

  static const String _chatsCollection = 'chats';
  static const String _messagesSubcollection = 'messages';

  static Future<void> sendMessage(ChatMessageModel message) async {
    await FirestoreService.collection(_chatsCollection)
        .doc(message.sessionId)
        .collection(_messagesSubcollection)
        .add(message.toMap());
  }

  /// Listen to Firestore messages — emits full list on each change
  static Stream<List<ChatMessageModel>> getChat(String sessionId) {
    return FirestoreService.collection(_chatsCollection)
        .doc(sessionId)
        .collection(_messagesSubcollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data()))
            .toList());
  }
}
