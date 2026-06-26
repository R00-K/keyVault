import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../infra/api/models/trust/trust_method.dart';
import '../../../../infra/api/models/trust/trust_payload_model.dart';
import '../../../../infra/api/models/trust/trust_session_model.dart';
import '../../../../infra/api/services/auth_service.dart';
import '../../../../infra/api/services/key_exchange_service.dart';
import '../../../../infra/api/services/user_service.dart';
import '../../../widgets/kv_button.dart';
import '../../../widgets/kv_section_card.dart';

class EstablishTrustQrScreen extends StatefulWidget {
  const EstablishTrustQrScreen({super.key});

  @override
  State<EstablishTrustQrScreen> createState() => _EstablishTrustQrScreenState();
}

class _EstablishTrustQrScreenState extends State<EstablishTrustQrScreen> {
  TrustSessionModel? _session;
  TrustPayloadModel? _payload;
  var _isPreparing = false;

  Future<void> _prepareQrTrust() async {
    if (_isPreparing) return;

    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in again.')));
      return;
    }

    setState(() {
      _isPreparing = true;
    });

    try {
      final profile = await UserService.getUser(currentUser.uid);
      print("PROFILE => ${profile?.toMap()}");
      final session = await KeyExchangeService.startTrustEstablishment(
        method: TrustMethod.qr,
      );
      print("SESSION => ${session.sessionId}");
      final payload = KeyExchangeService.buildQrPayload(
        session: session,
        keyVaultId: profile?.keyVaultId ?? currentUser.uid,
        displayName:
            profile?.displayName ??
            currentUser.displayName ??
            currentUser.email ??
            'KeyVault user',
      );
      print("PAYLOAD => ${payload.toMap()}");
      if (!mounted) return;
      setState(() {
        _session = session;
        _payload = payload;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR trust payload prepared.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not prepare QR trust.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreparing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    final session = _session;

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
                  child: Icon(Icons.qr_code_2_outlined),
                ),
                const SizedBox(height: 16),
                const Text('QR Code', style: AppTextTheme.heading),
                const SizedBox(height: 8),
                const Text(
                  'This screen will present trust material as a QR code.',
                  style: AppTextTheme.bodyMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Future steps: prepare public identity material, show QR, verify identity, then create a trusted contact.',
                  style: AppTextTheme.caption,
                ),
                const SizedBox(height: 18),
                KvButton(
                  label: _isPreparing ? 'Preparing...' : 'Prepare QR Trust',
                  icon: Icons.qr_code_2_outlined,
                  onPressed: _isPreparing ? null : _prepareQrTrust,
                ),
                if (payload != null && session != null) ...[
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Prepared Payload', style: AppTextTheme.heading),
                  const SizedBox(height: 8),
                  Text(
                    'Session ${session.sessionId}',
                    style: AppTextTheme.caption,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    payload.toMap().toString(),
                    style: AppTextTheme.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
