import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/kv_section_card.dart';

class EstablishTrustScreen extends StatelessWidget {
  const EstablishTrustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Establish Trust', style: AppTextTheme.title),
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
                  'Pick how this device should present trust material.',
                  style: AppTextTheme.bodyMuted,
                ),
                const SizedBox(height: 12),
                _TrustMethodTile(
                  icon: Icons.qr_code_2_outlined,
                  title: 'QR Code',
                  subtitle: 'Show a scannable trust payload.',
                  onTap: () => context.push(RouteNames.establishTrustQr),
                ),
                _TrustMethodTile(
                  icon: Icons.nfc_outlined,
                  title: 'NFC',
                  subtitle: 'Prepare this device for a tap flow.',
                  onTap: () => context.push(RouteNames.establishTrustNfc),
                ),
                _TrustMethodTile(
                  icon: Icons.keyboard_outlined,
                  title: 'Manual Trust',
                  subtitle: 'Prepare text-based verification material.',
                  onTap: () => context.push(RouteNames.establishTrustManual),
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
