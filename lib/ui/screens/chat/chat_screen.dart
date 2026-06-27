import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../chat/models/chat_message_model.dart';
import '../../../chat/services/chat_encryption_service.dart';
import '../../../chat/services/chat_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../infra/api/services/auth_service.dart';
import '../../routes/route_names.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.contactName,
    required this.sessionId,
    required this.to,
    required this.peerPublicKey,
    this.from,
  });

  final String contactName;
  final String sessionId;
  final String to;
  final String peerPublicKey;
  final String? from;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _messages = <_ChatMessage>[];
  final _scrollController = ScrollController();

  late final String _userId;
  StreamSubscription<ChatMessageModel>? _chatSubscription;
  var _isSending = false;

  @override
  void initState() {
    super.initState();
    _userId = widget.from ?? AuthService.currentUser?.uid ?? '';
    _listenForMessages();
  }

  void _listenForMessages() {
    _chatSubscription = ChatRepository.getChat(widget.sessionId).listen(
      (message) {
        if (!mounted) return;
        _decryptAndDisplay(message);
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat error: $error')),
        );
      },
    );
  }

  Future<void> _decryptAndDisplay(ChatMessageModel message) async {
    try {
      final plainText = await ChatEncryptionService.decryptMessage(
        message: message,
        peerPublicKey: widget.peerPublicKey,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: plainText,
          timestamp: message.timestamp,
          isMine: message.from == _userId,
          status: message.from == _userId ? _MessageStatus.sent : _MessageStatus.delivered,
        ));
      });
      _scrollToBottom();
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();

    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to send messages.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final encrypted = await ChatEncryptionService.encryptMessage(
        sessionId: widget.sessionId,
        from: _userId,
        to: widget.to,
        message: text,
        peerPublicKey: widget.peerPublicKey,
      );

      await ChatRepository.sendMessage(encrypted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _goBack() {
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.contactName,
                      style: AppTextTheme.heading,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Verified',
                          style: AppTextTheme.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Secure call',
              onPressed: _showComingSoon,
              icon: const Icon(Icons.call_outlined, size: 20),
            ),
            IconButton(
              tooltip: 'Video',
              onPressed: _showComingSoon,
              icon: const Icon(Icons.videocam_outlined, size: 20),
            ),
            PopupMenuButton<_ChatMenuAction>(
              tooltip: 'More options',
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (_) => _showComingSoon(),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _ChatMenuAction.viewContact,
                  child: Text('View contact'),
                ),
                PopupMenuItem(
                  value: _ChatMenuAction.verifyKey,
                  child: Text('Verify key'),
                ),
                PopupMenuItem(
                  value: _ChatMenuAction.clearChat,
                  child: Text('Clear chat'),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              size: 48,
                              color: AppColors.textSecondary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No messages yet',
                              style: AppTextTheme.heading,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Send a message to start the conversation.',
                              style: AppTextTheme.bodyMuted,
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        reverse: true,
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                        children: [
                          const SizedBox(height: 4),
                          for (final entry in _buildMessageGroups())
                            entry,
                        ],
                      ),
              ),
              _TrustBanner(),
              _MessageComposer(
                controller: _messageController,
                onSend: _sendMessage,
                isSending: _isSending,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMessageGroups() {
    final widgets = <Widget>[];
    String? lastDate;

    for (final message in _messages.reversed) {
      final dateStr = _formatDate(message.timestamp);

      if (dateStr != lastDate) {
        widgets.add(_DaySeparator(date: dateStr));
        lastDate = dateStr;
      }

      widgets.add(_MessageBubble(message: message));
    }

    return widgets;
  }

  String _formatDate(Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(dt.year, dt.month, dt.day);

    if (msgDate == today) return 'Today';
    if (msgDate == yesterday) return 'Yesterday';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This chat action is coming next.')),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(date, style: AppTextTheme.caption),
        ),
      ),
    );
  }
}

class _TrustBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 13,
            color: AppColors.success.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'End-to-end encrypted — physically verified',
              style: AppTextTheme.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 6),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMine ? AppColors.onPrimary : AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isMine
                            ? AppColors.onPrimary.withValues(alpha: 0.65)
                            : AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.status.icon,
                        size: 13,
                        color: message.status == _MessageStatus.read
                            ? (isMine ? AppColors.onPrimary : AppColors.primary)
                            : (isMine
                                ? AppColors.onPrimary.withValues(alpha: 0.5)
                                : AppColors.textSecondary.withValues(alpha: 0.5)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MessageComposer extends StatefulWidget {
  const _MessageComposer({
    required this.controller,
    required this.onSend,
    this.isSending = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    tooltip: 'Attach',
                    onPressed: () {},
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: TextField(
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => widget.onSend(),
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: widget.isSending ? null : widget.onSend,
              icon: widget.isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.arrow_upward, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChatMenuAction { viewContact, verifyKey, clearChat }

enum _MessageStatus {
  sent(Icons.check),
  delivered(Icons.done_all),
  read(Icons.done_all);

  const _MessageStatus(this.icon);

  final IconData icon;
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.timestamp,
    required this.isMine,
    required this.status,
  });

  final String text;
  final Timestamp timestamp;
  final bool isMine;
  final _MessageStatus status;
}
