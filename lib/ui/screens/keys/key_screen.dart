import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../infra/api/models/key_request_model.dart';
import '../../../infra/api/services/auth_service.dart';
import '../../../infra/api/services/TrustRequestService';
import '../../routes/route_names.dart';
import '../../widgets/kv_button.dart';
import '../../widgets/kv_section_card.dart';
import 'widgets/key_primary_actions_card.dart';
import 'widgets/key_request_section.dart';
import 'widgets/key_summary_card.dart';

class KeyScreen extends StatefulWidget {
  const KeyScreen({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<KeyScreen> createState() => _KeyScreenState();
}

class _KeyScreenState extends State<KeyScreen> {
  late Future<_KeyRequestsData> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _loadRequests();
  }

  @override
  void didUpdateWidget(covariant KeyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _requestsFuture = _loadRequests();
    }
  }

  Future<_KeyRequestsData> _loadRequests() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return const _KeyRequestsData(incoming: [], outgoing: []);
    }

    final requests = await Future.wait<List<KeyRequestModel>>([
      KeyService.getIncomingKeyRequests(userId: currentUser.uid),
      KeyService.getOutgoingKeyRequests(userId: currentUser.uid),
    ]);

    return _KeyRequestsData(incoming: requests[0], outgoing: requests[1]);
  }

  void _refreshRequests() {
    setState(() {
      _requestsFuture = _loadRequests();
    });
  }

  Future<void> _handleRequestAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      _refreshRequests();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update key request.')),
      );
    }
  }

  void _openEstablishTrust() {
    context.push(RouteNames.establishTrust);
  }

  void _openReceiveTrust() {
    context.push(RouteNames.receiveTrust);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_KeyRequestsData>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _KeysErrorView(onRetry: _refreshRequests);
        }

        final data = snapshot.data ?? const _KeyRequestsData();

        return RefreshIndicator(
          onRefresh: () async => _refreshRequests(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              KeyPrimaryActionsCard(
                onEstablishTrust: _openEstablishTrust,
                onReceiveTrust: _openReceiveTrust,
              ),
              const SizedBox(height: 12),
              KeySummaryCard(
                incomingCount: data.incoming.length,
                outgoingCount: data.outgoing.length,
                onRefresh: _refreshRequests,
              ),
              const SizedBox(height: 12),
              KeyRequestSection(
                title: 'Incoming key requests',
                emptyText: 'No incoming key requests.',
                requests: data.incoming,
                direction: KeyRequestDirection.incoming,
                onAccept: (request) => _handleRequestAction(
                  () => KeyService.acceptKeyRequest(request.id),
                  'Key request accepted.',
                ),
                onReject: (request) => _handleRequestAction(
                  () => KeyService.rejectKeyRequest(request.id),
                  'Key request rejected.',
                ),
                onCancel: null,
              ),
              const SizedBox(height: 12),
              KeyRequestSection(
                title: 'Outgoing key requests',
                emptyText: 'No outgoing key requests.',
                requests: data.outgoing,
                direction: KeyRequestDirection.outgoing,
                onAccept: null,
                onReject: null,
                onCancel: (request) => _handleRequestAction(
                  () => KeyService.cancelKeyRequest(request.id),
                  'Key request canceled.',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KeysErrorView extends StatelessWidget {
  const _KeysErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        KvSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.warning,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Keys could not be loaded',
                style: AppTextTheme.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection or Firestore permissions, then try again.',
                style: AppTextTheme.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              KvButton(
                label: 'Try again',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyRequestsData {
  const _KeyRequestsData({this.incoming = const [], this.outgoing = const []});

  final List<KeyRequestModel> incoming;
  final List<KeyRequestModel> outgoing;
}
