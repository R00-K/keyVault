import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.contactName});

  final String contactName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _messages = <_ChatMessage>[
    _ChatMessage(
      text: 'Trust key accepted. This chat is now locked to this device.',
      time: '09:12',
      isMine: false,
      status: _MessageStatus.read,
    ),
    _ChatMessage(
      text: 'Perfect. I like that it shows the verification method too.',
      time: '09:13',
      isMine: true,
      status: _MessageStatus.read,
    ),
    _ChatMessage(
      text: 'Lunch keys are ready to exchange.',
      time: '12:42',
      isMine: false,
      status: _MessageStatus.delivered,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          time: 'Now',
          isMine: true,
          status: _MessageStatus.sent,
        ),
      );
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.primary,
              child: Icon(Icons.lock_person_outlined, size: 20),
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
                  const SizedBox(height: 2),
                  const Text(
                    'Verified secure chat',
                    style: AppTextTheme.caption,
                    overflow: TextOverflow.ellipsis,
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
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            tooltip: 'Video',
            onPressed: _showComingSoon,
            icon: const Icon(Icons.videocam_outlined),
          ),
          PopupMenuButton<_ChatMenuAction>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert),
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
              child: ListView(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                children: [
                  for (final message in _messages.reversed)
                    _MessageBubble(message: message),
                  const _DayChip(label: 'Today'),
                  const _TrustBanner(),
                ],
              ),
            ),
            _MessageComposer(
              controller: _messageController,
              onSend: _sendMessage,
              onMore: _showComingSoon,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This chat action is coming next.')),
    );
  }
}

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Messages are protected by a physically verified contact key.',
              style: AppTextTheme.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: AppTextTheme.caption),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isMine
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = message.isMine ? AppColors.primaryMuted : AppColors.surface;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
      bottomLeft: Radius.circular(message.isMine ? 8 : 2),
      bottomRight: Radius.circular(message.isMine ? 2 : 8),
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(message.text, style: AppTextTheme.body),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.time, style: AppTextTheme.caption),
                if (message.isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status.icon,
                    size: 15,
                    color: message.status == _MessageStatus.read
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.onSend,
    required this.onMore,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Attach',
            onPressed: onMore,
            icon: const Icon(Icons.add_circle_outline),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Message',
                prefixIcon: Icon(Icons.lock_outline),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton.filled(
              tooltip: 'Send',
              onPressed: onSend,
              icon: const Icon(Icons.send),
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
    required this.time,
    required this.isMine,
    required this.status,
  });

  final String text;
  final String time;
  final bool isMine;
  final _MessageStatus status;
}
