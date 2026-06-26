import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/kv_section_card.dart';

class ReceiveTrustScreen extends StatelessWidget {
  const ReceiveTrustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Trust', style: AppTextTheme.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          KvSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Choose method', style: AppTextTheme.heading),
                const SizedBox(height: 6),
                const Text(
                  'Pick how this device should receive trust material.',
                  style: AppTextTheme.bodyMuted,
                ),
                const SizedBox(height: 12),
                _TrustMethodTile(
                  icon: Icons.qr_code_scanner_outlined,
                  title: 'Scan QR',
                  subtitle: 'Scan a trust payload from another device.',
                  onTap: () => context.push(RouteNames.receiveTrustQr),
                ),
                _TrustMethodTile(
                  icon: Icons.nfc_outlined,
                  title: 'NFC',
                  subtitle: 'Wait for a nearby device tap.',
                  onTap: () => context.push(RouteNames.receiveTrustNfc),
                ),
                _TrustMethodTile(
                  icon: Icons.keyboard_outlined,
                  title: 'Manual Entry',
                  subtitle: 'Enter verification material by hand.',
                  onTap: () => context.push(RouteNames.receiveTrustManual),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustMethodTile extends StatelessWidget {
  const _TrustMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
