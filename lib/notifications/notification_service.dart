import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../infra/api/services/contact_service.dart';
import '../ui/routes/app_router.dart';
import '../ui/routes/route_names.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await localNotifications.initialize(settings);

  final sessionId = message.data['sessionId'] as String?;
  final messageId = message.data['messageId'] as String?;
  final title = message.data['title'] as String? ?? 'KeyVault';
  final body = message.data['body'] as String? ?? 'New secure message';
  if (sessionId == null || messageId == null) return;

  const androidDetails = AndroidNotificationDetails(
    'secure_messages',
    'Secure Messages',
    channelDescription: 'Notifications for new secure messages',
    importance: Importance.high,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails();
  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await localNotifications.show(
    messageId.hashCode,
    title,
    body,
    details,
    payload: sessionId,
  );
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? _pendingSessionId;

  static String? get pendingSessionId => _pendingSessionId;

  static Future<void> initialize() async {
    await requestNotificationPermission();
    await initializeForegroundNotifications();
    handleTokenRefresh();
    initializeBackgroundNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final sessionId = initialMessage.data['sessionId'] as String?;
      if (sessionId != null && sessionId.isNotEmpty) {
        _pendingSessionId = sessionId;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await saveTokenToFirestore(user.uid);
    }
  }

  static Future<void> requestNotificationPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<String?> getDeviceToken() async {
    return _fcm.getToken();
  }

  static Future<void> saveTokenToFirestore(String userId) async {
    String? token;
    for (var i = 0; i < 3; i++) {
      token = await _fcm.getToken();
      if (token != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (token == null) {
      debugPrint('[NotificationService] Failed to get FCM token after 3 retries');
      return;
    }
    debugPrint('[NotificationService] Saving FCM token: ${token.substring(0, 20)}...');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  static void handleTokenRefresh() {
    _fcm.onTokenRefresh.listen((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        saveTokenToFirestore(user.uid);
      }
    });
  }

  static Future<void> initializeForegroundNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'secure_messages',
        'Secure Messages',
        description: 'Notifications for new secure messages',
        importance: Importance.high,
      ),
    );
  }

  static void initializeBackgroundNotifications() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final sessionId = message.data['sessionId'] as String?;
    final messageId = message.data['messageId'] as String?;
    final title = message.data['title'] as String? ?? 'KeyVault';
    final body = message.data['body'] as String? ?? 'New secure message';
    if (sessionId == null || messageId == null) return;

    const androidDetails = AndroidNotificationDetails(
      'secure_messages',
      'Secure Messages',
      channelDescription: 'Notifications for new secure messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      messageId.hashCode,
      title,
      body,
      details,
      payload: sessionId,
    );
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    final sessionId = message.data['sessionId'] as String?;
    if (sessionId == null || sessionId.isEmpty) return;
    await _navigateToSession(sessionId);
  }

  static Future<void> _onLocalNotificationTap(
      NotificationResponse response) async {
    final sessionId = response.payload;
    if (sessionId == null || sessionId.isEmpty) return;
    await _navigateToSession(sessionId);
  }

  static Future<void> _navigateToSession(String sessionId) async {
    final contact = await ContactService.getContactBySessionId(sessionId);
    final contactName = contact?.name ?? 'Contact';
    final to = contact?.to ?? '';
    final peerPublicKey = contact?.peerPublicKey ?? '';
    final from = FirebaseAuth.instance.currentUser?.uid;

    try {
      appRouter.go(
        RouteNames.chatFor(contactName),
        extra: <String, dynamic>{
          'sessionId': sessionId,
          'to': to,
          'peerPublicKey': peerPublicKey,
          'from': from,
        },
      );
    } catch (_) {
      _pendingSessionId = sessionId;
    }
  }
}
