import 'package:flutter/material.dart';

import 'package:keyvault/core/theme/app_theme.dart';
import 'package:keyvault/ui/routes/app_router.dart';

class KeyVaultApp extends StatelessWidget {
  const KeyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'KeyVault',
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
