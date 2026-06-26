import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../infra/api/models/trust/trust_method.dart';
import '../../../../infra/api/models/trust/trust_payload_model.dart';
import '../../../../infra/api/models/trust/trust_session_model.dart';
import '../../../../infra/api/services/auth_service.dart';
import '../../../../infra/api/services/key_exchange_service.dart';
import '../../../../infra/api/services/user_service.dart';
import '../../../widgets/kv_button.dart';

class EstablishTrustQrScreen extends StatefulWidget {
  const EstablishTrustQrScreen({super.key});

  @override
  State<EstablishTrustQrScreen> createState() => _EstablishTrustQrScreenState();
}

class _EstablishTrustQrScreenState extends State<EstablishTrustQrScreen> {
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

    setState(() => _isPreparing = true);

    try {
      final profile = await UserService.getUser(currentUser.uid);
      final session = await KeyExchangeService.startTrustEstablishment(
        method: TrustMethod.qr,
      );

      final payload = KeyExchangeService.buildQrPayload(
        session: session,
        keyVaultId: profile?.keyVaultId ?? currentUser.uid,
        displayName:
            profile?.displayName ??
            currentUser.displayName ??
            currentUser.email ??
            'KeyVault user',
      );

      final qrData = jsonEncode(payload.toMap());

      if (!mounted) return;
      setState(() => _isPreparing = false);

      _showQrSheet(session, payload, qrData);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPreparing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not prepare QR trust.')),
      );
    }
  }

  void _showQrSheet(
    TrustSessionModel session,
    TrustPayloadModel payload,
    String qrData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrSheet(
        session: session,
        payload: payload,
        qrData: qrData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Establish Trust', style: AppTextTheme.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.qr_code_2_outlined, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'QR Trust Establishment',
                style: AppTextTheme.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Generate a QR code containing your public identity material. The receiving device scans it to establish a secure trust relationship.',
                style: AppTextTheme.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              KvButton(
                label: _isPreparing ? 'Preparing...' : 'Prepare QR Trust',
                icon: Icons.qr_code_2_outlined,
                onPressed: _isPreparing ? null : _prepareQrTrust,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrSheet extends StatelessWidget {
  const _QrSheet({
    required this.session,
    required this.payload,
    required this.qrData,
  });

  final TrustSessionModel session;
  final TrustPayloadModel payload;
  final String qrData;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Scan this QR code',
              style: AppTextTheme.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Have the receiving device scan this code.',
              style: AppTextTheme.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Session ${session.sessionId}',
                  style: AppTextTheme.caption,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Debug Payload', style: AppTextTheme.body),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(payload.toMap()),
                    style: AppTextTheme.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Close', style: AppTextTheme.body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
