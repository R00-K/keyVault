import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../watch/models/watch_session_model.dart';
import '../../../watch/services/watch_service.dart';
import '../../routes/route_names.dart';

class WatchingScreen extends StatefulWidget {
  const WatchingScreen({super.key, required this.watchSessionId});

  final String watchSessionId;

  @override
  State<WatchingScreen> createState() => _WatchingScreenState();
}

class _WatchingScreenState extends State<WatchingScreen> {
  StreamSubscription<WatchSessionModel?>? _sessionSubscription;
  WatchSessionModel? _session;
  bool _isHost = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _isHost = true;
    _sessionSubscription =
        WatchService.listenWatchSession(widget.watchSessionId).listen(
      (session) {
        if (!mounted) return;
        if (session == null) {
          context.go(RouteNames.home);
          return;
        }
        setState(() => _session = session);
        if (uid != null) {
          _isHost = session.hostUid == uid;
        }
        if (session.watchState == WatchState.ended) {
          _handleSessionEnded();
        }
      },
    );
  }

  void _handleSessionEnded() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Ended'),
        content: const Text('The Watch Together session has ended.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(RouteNames.home);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _endSession() async {
    await WatchService.endWatchSession(widget.watchSessionId);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Together'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isHost ? _endSession : () => context.go(RouteNames.home),
        ),
      ),
      body: session == null
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(session),
    );
  }

  Widget _buildContent(WatchSessionModel session) {
    if (session.watchState == WatchState.waiting ||
        session.watchState == WatchState.accepted ||
        session.watchState == WatchState.connecting) {
      return _buildWaitingContent(session);
    }
    return _buildStreamContent(session);
  }

  Widget _buildWaitingContent(WatchSessionModel session) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.visibility_outlined,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              session.videoName,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _InfoRow(label: 'State', value: _stateLabel(session.watchState)),
            const SizedBox(height: 8),
            _InfoRow(label: 'Host', value: session.hostUid),
            const SizedBox(height: 8),
            _InfoRow(label: 'Viewer', value: session.viewerUid),
            const SizedBox(height: 32),
            if (_isHost)
              FilledButton.icon(
                onPressed: _endSession,
                icon: const Icon(Icons.stop),
                label: const Text('End Session'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamContent(WatchSessionModel session) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.live_tv, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              session.videoName,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _stateLabel(session.watchState),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.construction, size: 48, color: Colors.white24),
                  SizedBox(height: 12),
                  Text(
                    'Streaming engine will be implemented here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_isHost)
              FilledButton.icon(
                onPressed: _endSession,
                icon: const Icon(Icons.stop),
                label: const Text('End Session'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _stateLabel(WatchState state) {
    switch (state) {
      case WatchState.waiting:
        return 'Waiting for viewer...';
      case WatchState.accepted:
        return 'Accepted — Connecting...';
      case WatchState.connecting:
        return 'Connecting...';
      case WatchState.streaming:
        return 'Streaming';
      case WatchState.paused:
        return 'Paused';
      case WatchState.ended:
        return 'Ended';
      case WatchState.cancelled:
        return 'Cancelled';
      case WatchState.failed:
        return 'Failed';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white54,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
