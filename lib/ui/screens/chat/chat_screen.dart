import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../chat/models/chat_message_model.dart';
import '../../../chat/services/chat_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../crypto/secure_key_storage.dart';
import '../../../infra/api/services/auth_service.dart';
import '../../../infra/api/services/contact_service.dart';
import '../../../watch/services/watch_service.dart';
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
  StreamSubscription<List<ChatMessageModel>>? _localSubscription;
  var _isSending = false;

  @override
  void initState() {
    super.initState();
    _userId = widget.from ?? AuthService.currentUser?.uid ?? '';
    ChatService.startSync(
      sessionId: widget.sessionId,
      peerPublicKey: widget.peerPublicKey,
    );
    _listenLocalMessages();
  }

  void _listenLocalMessages() {
    _localSubscription = ChatService.getMessagesStream(widget.sessionId).listen(
      (messages) {
        if (!mounted) return;
        setState(() {
          _messages.clear();
          for (final msg in messages) {
            final plainText = msg.plainText;
            if (plainText == null) continue;
            _messages.add(_ChatMessage(
              text: plainText,
              timestamp: msg.timestamp,
              isMine: msg.from == _userId,
              status: msg.from == _userId
                  ? _MessageStatus.sent
                  : _MessageStatus.delivered,
            ));
          }
        });
        _scrollToBottom();
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat error: $error')),
        );
      },
    );
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
    _localSubscription?.cancel();
    ChatService.stopSync();
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
      await ChatService.sendMessage(
        sessionId: widget.sessionId,
        from: _userId,
        to: widget.to,
        message: text,
        peerPublicKey: widget.peerPublicKey,
      );
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
              onSelected: _handleMenuAction,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _ChatMenuAction.clearChat,
                  child: ListTile(
                    leading: Icon(Icons.delete_sweep_outlined, size: 20),
                    title: Text('Clear chat'),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                PopupMenuItem(
                  value: _ChatMenuAction.deleteChat,
                  child: ListTile(
                    leading: Icon(Icons.delete_forever_outlined, size: 20),
                    title: Text('Delete chat'),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
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
                onWatchFile: _handleWatchFile,
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

  String _formatDate(int timestampMs) {
    final dt =
        DateTime.fromMillisecondsSinceEpoch(timestampMs);
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

  Future<void> _handleWatchFile() async {
    await _showAttachmentSheet();
  }

  Future<void> _showAttachmentSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ModernAttachmentTile(
                    icon: Icons.photo_library_outlined,
                    label: 'Photos',
                    color: const Color(0xFF4CAF50),
                    onTap: () => Navigator.pop(ctx, 'photos'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModernAttachmentTile(
                    icon: Icons.videocam_outlined,
                    label: 'Videos',
                    color: const Color(0xFF2196F3),
                    onTap: () => Navigator.pop(ctx, 'videos'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModernAttachmentTile(
                    icon: Icons.description_outlined,
                    label: 'Documents',
                    color: const Color(0xFFFF9800),
                    onTap: () => Navigator.pop(ctx, 'documents'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModernAttachmentTile(
                    icon: Icons.visibility_outlined,
                    label: 'Watch Together',
                    color: const Color(0xFF9C27B0),
                    highlighted: true,
                    onTap: () => Navigator.pop(ctx, 'watch'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    switch (result) {
      case 'photos':
      case 'videos':
      case 'documents':
        _showComingSoon();
      case 'watch':
        await _pickAndSendWatchInvite();
    }
  }

  Future<void> _pickAndSendWatchInvite() async {
    final localVideo = await WatchService.pickVideo();
    if (localVideo == null) return;

    final session = await WatchService.startWatchSession(
      chatSessionId: widget.sessionId,
      viewerUid: widget.to,
      localVideo: localVideo,
    );

    if (!mounted) return;
    context.go(RouteNames.watchFor(session.watchSessionId));
  }

  void _handleMenuAction(_ChatMenuAction action) {
    switch (action) {
      case _ChatMenuAction.clearChat:
        _clearChat();
      case _ChatMenuAction.deleteChat:
        _deleteChat();
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat?'),
        content: Text(
            'All messages with ${widget.contactName} will be removed from this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear')),
        ],
      ),
    );

    if (confirmed != true) return;
    await ChatService.clearChat(widget.sessionId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat cleared')),
    );
  }

  Future<void> _deleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text(
            'This will remove all messages and delete ${widget.contactName} from your contacts.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ChatService.clearChat(widget.sessionId);
    await ContactService.removeContact(widget.sessionId);
    await SecureKeyStorage.deletePrivateKey(sessionId: widget.sessionId);
    await SecureKeyStorage.deletePublicKey(sessionId: widget.sessionId);

    await ContactService.loadContacts();

    if (!mounted) return;
    context.go(RouteNames.home);
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

  String _formatTime(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
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
    this.onWatchFile,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final VoidCallback? onWatchFile;

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
                    onPressed: widget.onWatchFile,
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

enum _ChatMenuAction { clearChat, deleteChat }

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
  final int timestamp;
  final bool isMine;
  final _MessageStatus status;
}

class _ModernAttachmentTile extends StatelessWidget {
  const _ModernAttachmentTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: highlighted
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: highlighted
              ? Border.all(color: color.withValues(alpha: 0.3))
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
                color: highlighted ? color : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
