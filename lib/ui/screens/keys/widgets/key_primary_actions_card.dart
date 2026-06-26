import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_theme.dart';
import '../../../widgets/kv_section_card.dart';

class KeyPrimaryActionsCard extends StatelessWidget {
  const KeyPrimaryActionsCard({
    super.key,
    required this.onEstablishTrust,
    required this.onReceiveTrust,
  });

  final VoidCallback onEstablishTrust;
  final VoidCallback onReceiveTrust;

  @override
  Widget build(BuildContext context) {
    return KvSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Keys', style: AppTextTheme.heading),
          const SizedBox(height: 6),
          const Text(
            'Start by establishing trust, then continue into a trusted contact.',
            style: AppTextTheme.bodyMuted,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onEstablishTrust,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Establish Trust'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onReceiveTrust,
            icon: const Icon(Icons.qr_code_scanner_outlined),
            label: const Text('Receive Trust'),
          ),
        ],
      ),
    );
  }
}
