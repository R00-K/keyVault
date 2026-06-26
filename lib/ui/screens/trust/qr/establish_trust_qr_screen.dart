import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../infra/api/models/trust/trust_method.dart';
import '../../../../infra/api/models/trust/trust_payload_model.dart';
import '../../../../infra/api/models/trust/trust_session_model.dart';
import '../../../../infra/api/services/auth_service.dart';
import '../../../../infra/api/services/key_exchange_service.dart';
import '../../../../infra/api/services/trust_event_service.dart';
import '../../../../infra/api/services/user_service.dart';
import '../../../routes/route_names.dart';
import '../../../widgets/kv_button.dart';
import 'qr_scanner_screen.dart';

enum _HandshakeStage { waiting, scanned, completed }

class EstablishTrustQrScreen extends StatefulWidget {
  const EstablishTrustQrScreen({super.key});

  @override
  State<EstablishTrustQrScreen> createState() =>
      _EstablishTrustQrScreenState();
}

class _EstablishTrustQrScreenState extends State<EstablishTrustQrScreen> {
  var _isPreparing = false;

  Future<void> _prepareQrTrust() async {
    if (_isPreparing) return;

    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
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

      final contactName = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _QrSheet(
          session: session,
          payload: payload,
          qrData: qrData,
        ),
      );

      if (contactName != null && mounted) {
        context.go(RouteNames.chatFor(contactName));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPreparing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not prepare QR trust.')),
      );
    }
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
                child: const Icon(
                  Icons.qr_code_2_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
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

class _QrSheet extends StatefulWidget {
  const _QrSheet({
    required this.session,
    required this.payload,
    required this.qrData,
  });

  final TrustSessionModel session;
  final TrustPayloadModel payload;
  final String qrData;

  @override
  State<_QrSheet> createState() => _QrSheetState();
}

class _QrSheetState extends State<_QrSheet> {
  StreamSubscription<dynamic>? _eventSub;
  var _stage = _HandshakeStage.waiting;
  var _isScanningResponse = false;

  @override
  void initState() {
    super.initState();
    _eventSub = TrustEventService.eventStream(
      sessionId: widget.session.sessionId,
    ).listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data();
      if (data?['type'] == 'trust_qr_scanned') {
        setState(() => _stage = _HandshakeStage.scanned);
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _scanResponseQr() async {
    if (_isScanningResponse) return;

    final payload = await Navigator.of(context).push<TrustPayloadModel>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (payload == null || !mounted) return;

    setState(() => _isScanningResponse = true);

    try {
      await KeyExchangeService.completeTrustWithResponse(
        session: widget.session,
        responsePayload: payload,
      );

      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        final profile = await UserService.getUser(currentUser.uid);
        await TrustEventService.notifyTrustEstablished(
          sessionId: widget.session.sessionId,
          receiverKeyVaultId: profile?.keyVaultId ?? currentUser.uid,
        );
      }

      if (!mounted) return;
      setState(() => _stage = _HandshakeStage.completed);

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(payload.displayName);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isScanningResponse = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete trust handshake.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _stage == _HandshakeStage.completed
          ? _buildCompletedSheet()
          : _buildActiveSheet(),
    );
  }

  Widget _buildActiveSheet() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      key: const ValueKey('active'),
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
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _stage == _HandshakeStage.scanned
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _stage == _HandshakeStage.scanned
                        ? Icons.check_circle
                        : Icons.hourglass_empty,
                    color: _stage == _HandshakeStage.scanned
                        ? AppColors.success
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _stage == _HandshakeStage.scanned
                          ? 'QR Successfully Scanned\nPlease scan the QR displayed on the other device.'
                          : 'Waiting for the other user to scan...',
                      style: AppTextTheme.caption,
                    ),
                  ),
                  if (_stage == _HandshakeStage.waiting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_stage == _HandshakeStage.scanned)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isScanningResponse ? null : _scanResponseQr,
                        icon: _isScanningResponse
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.qr_code_scanner_outlined),
                        label: Text(
                          _isScanningResponse
                              ? 'Processing...'
                              : 'Scan Response QR',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                  data: widget.qrData,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Session ${widget.session.sessionId}',
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
                    const JsonEncoder.withIndent('  ').convert(
                      widget.payload.toMap(),
                    ),
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

  Widget _buildCompletedSheet() {
    return DraggableScrollableSheet(
      key: const ValueKey('completed'),
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.6,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Trust Successfully\nEstablished',
              style: AppTextTheme.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You can now securely chat with ${widget.payload.displayName}.',
              style: AppTextTheme.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
