import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../infra/api/models/trust/trust_payload_model.dart';
import '../../../../infra/api/models/trust/trust_session_model.dart';
import '../../../../infra/api/services/auth_service.dart';
import '../../../../infra/api/services/key_exchange_service.dart';
import '../../../../infra/api/services/trust_event_service.dart';
import '../../../../infra/api/services/user_service.dart';
import '../../../widgets/kv_button.dart';
import '../../../widgets/kv_section_card.dart';
import 'qr_scanner_screen.dart';

class ReceiveTrustQrScreen extends StatefulWidget {
  const ReceiveTrustQrScreen({super.key});

  @override
  State<ReceiveTrustQrScreen> createState() => _ReceiveTrustQrScreenState();
}

class _ReceiveTrustQrScreenState extends State<ReceiveTrustQrScreen> {
  TrustSessionModel? _session;
  TrustPayloadModel? _responsePayload;
  String? _responseQrData;
  var _isProcessing = false;

  Future<void> _startScan() async {
    if (_isProcessing) return;

    final payload = await Navigator.of(context).push<TrustPayloadModel>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (payload == null) return;

    setState(() => _isProcessing = true);

    try {
      await TrustEventService.notifyQrScanned(
        sessionId: payload.sessionId,
        receiverKeyVaultId: payload.keyVaultId,
      );

      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in again.')),
        );
        return;
      }

      final session = await KeyExchangeService.receiveTrustRequest(
        payload: payload,
      );

      final profile = await UserService.getUser(currentUser.uid);

      final responsePayload = KeyExchangeService.generateResponsePayload(
        session: session,
        keyVaultId: profile?.keyVaultId ?? currentUser.uid,
        displayName:
            profile?.displayName ??
            currentUser.displayName ??
            currentUser.email ??
            'KeyVault user',
      );

      final qrData = jsonEncode(responsePayload.toMap());

      if (!mounted) return;
      setState(() {
        _session = session;
        _responsePayload = responsePayload;
        _responseQrData = qrData;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trust payload received successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process trust request.')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _responseQrData;
    final session = _session;
    final responsePayload = _responsePayload;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          qrData != null ? 'Trust Received' : 'Receive Trust',
          style: AppTextTheme.title,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (qrData == null)
            KvSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primaryMuted,
                    foregroundColor: AppColors.primary,
                    child: Icon(Icons.qr_code_scanner_outlined),
                  ),
                  const SizedBox(height: 16),
                  const Text('Scan QR', style: AppTextTheme.heading),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan the QR code displayed on the other device to receive their trust material.',
                    style: AppTextTheme.bodyMuted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'After scanning, the trust payload will be processed and a session will be established.',
                    style: AppTextTheme.caption,
                  ),
                  const SizedBox(height: 18),
                  KvButton(
                    label: _isProcessing ? 'Processing...' : 'Start QR Scan',
                    icon: Icons.qr_code_scanner_outlined,
                    onPressed: _isProcessing ? null : _startScan,
                  ),
                ],
              ),
            ),
          if (qrData != null) ...[
            KvSectionCard(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Trust Request Received',
                    style: AppTextTheme.heading,
                  ),
                  const SizedBox(height: 24),
                  Container(
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
                  const SizedBox(height: 16),
                  const Text(
                    'Ask the other device to scan this QR code.',
                    style: AppTextTheme.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Session ${session?.sessionId ?? ''}',
                      style: AppTextTheme.caption,
                    ),
                  ),
                  if (responsePayload != null) ...[
                    const SizedBox(height: 8),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Debug Response Payload',
                        style: AppTextTheme.body,
                      ),
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
                            const JsonEncoder.withIndent('  ').convert(
                              responsePayload.toMap(),
                            ),
                            style: AppTextTheme.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
