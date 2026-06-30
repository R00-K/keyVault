import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'chat/services/chat_service.dart';
import 'chat/storage/local_chat_storage.dart';
import 'chat/sync/chat_sync_service.dart';
import 'firebase_options.dart';
import 'infra/api/services/firestore_service.dart';
import 'infra/api/services/user_service.dart';
import 'notifications/notification_service.dart';
import 'ui/app.dart';
import 'ui/routes/app_router.dart';
import 'ui/routes/route_names.dart';
import 'watch/models/watch_session_model.dart';
import 'watch/services/watch_service.dart';

StreamSubscription<List<WatchSessionModel>>? _incomingSessionsSub;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirestoreService.initialize();
    NotificationService.initializeBackgroundNotifications();

    final localStorage = LocalChatStorage();
    await localStorage.initialize();

    final syncService = ChatSyncService(localStorage: localStorage);
    ChatService.initialize(
      localStorage: localStorage,
      syncService: syncService,
    );

    await NotificationService.initialize();

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      await _incomingSessionsSub?.cancel();
      if (user != null) {
        await NotificationService.saveTokenToFirestore(user.uid);
        _incomingSessionsSub =
            WatchService.listenIncomingSessions(user.uid).listen(
          (sessions) {
            for (final session in sessions) {
              _showIncomingSessionDialog(session);
            }
          },
        );
      }
    });
  } catch (e, stack) {
    // ignore: avoid_print
    print('Initialization error: $e\n$stack');
    runApp(ErrorApp(message: 'Failed to initialize: $e'));
    return;
  }

  runApp(const KeyVaultApp());

  final pendingSessionId = NotificationService.pendingSessionId;
  if (pendingSessionId != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appRouter.go(
        RouteNames.chatFor('Contact'),
        extra: <String, dynamic>{
          'sessionId': pendingSessionId,
          'to': '',
          'peerPublicKey': '',
          'from': null,
        },
      );
    });
  }
}

void _showIncomingSessionDialog(WatchSessionModel session) async {
  final ctx = appContext;
  if (ctx == null) return;

  final host = await UserService.getUser(session.hostUid);
  if (!ctx.mounted) return;
  final hostName = host?.displayName ?? 'Someone';

  showDialog(
    context: ctx,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      title: Text('$hostName wants to watch together'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.videoName),
          const SizedBox(height: 4),
          Text(
            _formatFileSize(session.videoSize),
            style: Theme.of(dialogCtx).textTheme.bodySmall?.copyWith(
              color: Theme.of(dialogCtx).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            WatchService.rejectWatchSession(session.watchSessionId);
            Navigator.of(dialogCtx).pop();
          },
          child: const Text('Decline'),
        ),
        FilledButton(
          onPressed: () {
            WatchService.acceptWatchSession(session.watchSessionId);
            Navigator.of(dialogCtx).pop();
            appRouter.go(RouteNames.watchFor(session.watchSessionId));
          },
          child: const Text('Accept'),
        ),
      ],
    ),
  );
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
