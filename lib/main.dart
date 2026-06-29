import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'chat/services/chat_service.dart';
import 'chat/storage/local_chat_storage.dart';
import 'chat/sync/chat_sync_service.dart';
import 'infra/api/services/firestore_service.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirestoreService.initialize();

  final localStorage = LocalChatStorage();
  await localStorage.initialize();

  final syncService = ChatSyncService(localStorage: localStorage);
  ChatService.initialize(
    localStorage: localStorage,
    syncService: syncService,
  );

  runApp(const KeyVaultApp());
}
