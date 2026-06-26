import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../../infra/api/models/key_request_model.dart';
import 'key_request_section.dart';

class KeyRequestTile extends StatelessWidget {
  const KeyRequestTile({
    super.key,
    required this.request,
    required this.direction,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
  });

  final KeyRequestModel request;
  final KeyRequestDirection direction;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final userId = direction == KeyRequestDirection.incoming
        ? request.senderId
        : request.receiverId;
    final label = direction == KeyRequestDirection.incoming
        ? 'From ${_shortId(userId)}'
        : 'To ${_shortId(userId)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.surfaceVariant,
            foregroundColor: AppColors.primary,
            child: Icon(Icons.vpn_key_outlined, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextTheme.body,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Pending • ${_formatTimestamp(request.createdAt)}',
                  style: AppTextTheme.caption,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onAccept != null)
                      _KeyActionButton(
                        tooltip: 'Accept key request',
                        icon: Icons.check,
                        onPressed: onAccept,
                      ),
                    if (onReject != null)
                      _KeyActionButton(
                        tooltip: 'Reject key request',
                        icon: Icons.close,
                        onPressed: onReject,
                      ),
                    if (onCancel != null)
                      _KeyActionButton(
                        tooltip: 'Cancel key request',
                        icon: Icons.delete_outline,
                        onPressed: onCancel,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 10) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }
}

class _KeyActionButton extends StatelessWidget {
  const _KeyActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 40,
        child: IconButton.outlined(
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
        ),
      ),
    );
  }
}
