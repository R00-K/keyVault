import 'package:flutter/material.dart';
import '../../../../infra/api/models/trust/trust_payload_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../infra/api/services/key_exchange_service.dart';
import '../../../widgets/kv_button.dart';
import '../../../widgets/kv_section_card.dart';

class EstablishTrustManualScreen extends StatelessWidget {
  const EstablishTrustManualScreen({super.key});

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryMuted,
                  foregroundColor: AppColors.primary,
                  child: Icon(Icons.keyboard_outlined),
                ),
                const SizedBox(height: 16),
                const Text('Manual Trust', style: AppTextTheme.heading),
                const SizedBox(height: 8),
                const Text(
                  'This screen will prepare trust material for manual verification.',
                  style: AppTextTheme.bodyMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Future steps: display verification material, compare fingerprints, then create a trusted contact.',
                  style: AppTextTheme.caption,
                ),
                const SizedBox(height: 18),
                KvButton(
                  label: 'Prepare Manual Trust',
                  icon: Icons.keyboard_outlined,
                  onPressed: () async {
await KeyExchangeService.receiveTrustRequest(
  payload: TrustPayloadModel(
    sessionId: "temp-session",
    keyVaultId: "temp-keyvault",
    displayName: "temp-user",
    publicKey: "temp-public-key",
    timestamp: DateTime.now().millisecondsSinceEpoch,
  ),
);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Manual trust setup is a placeholder.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
