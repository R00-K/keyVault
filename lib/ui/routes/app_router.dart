import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/trust/establish/establish_trust_screen.dart';
import '../screens/trust/manual/establish_trust_manual_screen.dart';
import '../screens/trust/manual/receive_trust_manual_screen.dart';
import '../screens/trust/nfc/establish_trust_nfc_screen.dart';
import '../screens/trust/nfc/receive_trust_nfc_screen.dart';
import '../screens/trust/qr/establish_trust_qr_screen.dart';
import '../screens/trust/qr/receive_trust_qr_screen.dart';
import '../screens/trust/recieve/receive_trust_screen.dart';
import '../screens/watch/watching_screen.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

BuildContext? get appContext => _rootNavigatorKey.currentContext;

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: RouteNames.completeProfile,
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: RouteNames.chat,
      builder: (context, state) {
        final contactName = state.pathParameters['contactName'] ?? 'Contact';
        final extra = state.extra as Map<String, dynamic>?;
        return ChatScreen(
          contactName: contactName,
          sessionId: extra?['sessionId'] as String? ?? '',
          to: extra?['to'] as String? ?? '',
          peerPublicKey: extra?['peerPublicKey'] as String? ?? '',
          from: extra?['from'] as String?,
        );
      },
    ),
    GoRoute(
      path: RouteNames.establishTrust,
      builder: (context, state) => const EstablishTrustScreen(),
    ),
    GoRoute(
      path: RouteNames.receiveTrust,
      builder: (context, state) => const ReceiveTrustScreen(),
    ),
    GoRoute(
      path: RouteNames.establishTrustQr,
      builder: (context, state) => const EstablishTrustQrScreen(),
    ),
    GoRoute(
      path: RouteNames.receiveTrustQr,
      builder: (context, state) => const ReceiveTrustQrScreen(),
    ),
    GoRoute(
      path: RouteNames.establishTrustNfc,
      builder: (context, state) => const EstablishTrustNfcScreen(),
    ),
    GoRoute(
      path: RouteNames.receiveTrustNfc,
      builder: (context, state) => const ReceiveTrustNfcScreen(),
    ),
    GoRoute(
      path: RouteNames.establishTrustManual,
      builder: (context, state) => const EstablishTrustManualScreen(),
    ),
    GoRoute(
      path: RouteNames.receiveTrustManual,
      builder: (context, state) => const ReceiveTrustManualScreen(),
    ),
    GoRoute(
      path: RouteNames.watch,
      builder: (context, state) {
        final watchSessionId = state.pathParameters['watchSessionId'] ?? '';
        return WatchingScreen(watchSessionId: watchSessionId);
      },
    ),
  ],
);
