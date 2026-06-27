import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../infra/api/services/auth_service.dart';
import '../../routes/route_names.dart';
import '../../widgets/kv_logo.dart';
import '../../widgets/kv_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      final route = AuthService.currentUser == null
          ? RouteNames.login
          : RouteNames.home;
      context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const pagePadding = 48; // KvPage uses EdgeInsets.all(24)

    return KvPage(
      child: SizedBox(
        height: viewHeight - topPadding - bottomPadding - pagePadding,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KvLogo(),
            SizedBox(height: 36),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
