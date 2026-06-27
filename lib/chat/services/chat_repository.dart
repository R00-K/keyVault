import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:keyvault/infra/api/services/firestore_service.dart';
import 'package:keyvault/chat/models/chat_message_model.dart';

class ChatRepository {
  ChatRepository._();

  static const String _chatsCollection = 'chats';
  static const String _messagesSubcollection = 'messages';

  /// Send (persist) an already-encrypted [ChatMessageModel] to Firestore.
  static Future<void> sendMessage(ChatMessageModel message) async {
    await FirestoreService.collection(_chatsCollection)
        .doc(message.sessionId)
        .collection(_messagesSubcollection)
        .add(message.toMap());
  }

  /// Listen for new messages addressed to [userId] across all chats.
  /// Returns a [Stream] of [ChatMessageModel] that can be cancelled.
  static Stream<ChatMessageModel> listenMessages(String userId) {
    final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

    stream = FirestoreService.instance.collectionGroup(_messagesSubcollection)
        .where('to', isEqualTo: userId)
        .orderBy('timestamp', descending: false)
        .snapshots();

    return stream.map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromMap(doc.data());
      });
    }).asyncExpand((messages) => Stream.fromIterable(messages));
  }

  /// Stream messages for a specific chat session, ordered by timestamp.
  static Stream<ChatMessageModel> getChat(String sessionId) {
    return FirestoreService.collection(_chatsCollection)
        .doc(sessionId)
        .collection(_messagesSubcollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromMap(doc.data());
      });
    }).asyncExpand((messages) => Stream.fromIterable(messages));
  }
}
