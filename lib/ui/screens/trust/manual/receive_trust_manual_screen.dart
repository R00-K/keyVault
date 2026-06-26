import 'package:flutter/material.dart';
import '../../../../infra/api/models/trust/trust_payload_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../infra/api/services/key_exchange_service.dart';
import '../../../widgets/kv_button.dart';
import '../../../widgets/kv_section_card.dart';

class ReceiveTrustManualScreen extends StatelessWidget {
  const ReceiveTrustManualScreen({super.key});

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryMuted,
                  foregroundColor: AppColors.primary,
                  child: Icon(Icons.keyboard_outlined),
                ),
                const SizedBox(height: 16),
                const Text('Manual Entry', style: AppTextTheme.heading),
                const SizedBox(height: 8),
                const Text(
                  'This screen will receive manually entered trust material.',
                  style: AppTextTheme.bodyMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Future steps: enter verification material, compare fingerprints, derive trust state, then create a trusted contact.',
                  style: AppTextTheme.caption,
                ),
                const SizedBox(height: 18),
                KvButton(
                  label: 'Enter Trust Material',
                  icon: Icons.keyboard_outlined,
                  onPressed: () async {
                    await KeyExchangeService.receiveTrustRequest(
                      payload: TrustPayloadModel(
                        sessionId: "temp-session",
                        keyVaultId: "temp-keyvault",
                        displayName: "temp-user",
                        publicKey: "temp-public-key",
                        timestamp: DateTime.now().millisecondsSinceEpoch,
                           isResponse: false,
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Manual trust receiving is a placeholder.',
                          ),
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
