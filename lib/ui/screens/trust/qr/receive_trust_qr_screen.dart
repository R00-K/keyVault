import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../infra/api/models/trust/trust_payload_model.dart';
import '../../../../infra/api/models/trust/trust_session_model.dart';
import '../../../../infra/api/services/auth_service.dart';
import '../../../../infra/api/services/contact_service.dart';
import '../../../../infra/api/services/key_exchange_service.dart';
import '../../../../infra/api/services/trust_event_service.dart';
import '../../../../infra/api/services/user_service.dart';
import '../../../routes/route_names.dart';
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
  StreamSubscription<dynamic>? _eventSub;
  var _trustEstablished = false;
  String? _contactDisplayName;
  String? _contactKeyVaultId;
  String? _contactPublicKey;

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isProcessing) return;

    final payload = await Navigator.of(context).push<TrustPayloadModel>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (payload == null) return;

    _contactDisplayName = payload.displayName;
    _contactKeyVaultId = payload.keyVaultId;
    _contactPublicKey = payload.publicKey;

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

      _eventSub = TrustEventService.eventStream(
        sessionId: payload.sessionId,
      ).listen((snapshot) {
        if (!snapshot.exists || !mounted) return;
        final data = snapshot.data();
        if (data?['type'] == 'trust_established') {
          ContactService.addContact(TrustedContact(
            name: _contactDisplayName ?? 'Contact',
            verification: 'QR verified',
            messagePreview: 'Trust established',
            sessionId: payload.sessionId,
            to: _contactKeyVaultId ?? '',
            peerPublicKey: _contactPublicKey ?? '',
          ));

          setState(() => _trustEstablished = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              final contactName = _contactDisplayName ?? 'Contact';
              context.go(
                RouteNames.chatFor(contactName),
                extra: <String, dynamic>{
                  'sessionId': payload.sessionId,
                  'to': _contactKeyVaultId ?? '',
                  'peerPublicKey': _contactPublicKey ?? '',
                  'from': AuthService.currentUser?.uid ?? '',
                },
              );
            }
          });
        }
      });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _trustEstablished
              ? 'Trust Established'
              : qrData != null
                  ? 'Trust Received'
                  : 'Receive Trust',
          style: AppTextTheme.title,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _trustEstablished
            ? _buildTrustEstablished()
            : qrData == null
                ? _buildScanView()
                : _buildResponseQrView(),
      ),
    );
  }

  Widget _buildScanView() {
    return ListView(
      key: const ValueKey('scan'),
      padding: const EdgeInsets.all(16),
      children: [
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
      ],
    );
  }

  Widget _buildResponseQrView() {
    final session = _session;
    final responsePayload = _responsePayload;

    return ListView(
      key: const ValueKey('response'),
      padding: const EdgeInsets.all(16),
      children: [
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
                  color: AppColors.onPrimary,
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
                  data: _responseQrData!,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: AppColors.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ask the other device to scan this QR code.',
                style: AppTextTheme.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Waiting for the other device to complete...',
                      style: AppTextTheme.caption,
                    ),
                  ],
                ),
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
    );
  }

  Widget _buildTrustEstablished() {
    return Center(
      key: const ValueKey('established'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 56,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'Trust Successfully\nEstablished',
              style: AppTextTheme.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You can now securely chat with ${_contactDisplayName ?? 'your contact'}.',
              style: AppTextTheme.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
