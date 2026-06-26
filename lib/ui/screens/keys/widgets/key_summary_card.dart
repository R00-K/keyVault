import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../../../widgets/kv_section_card.dart';

class KeySummaryCard extends StatelessWidget {
  const KeySummaryCard({
    super.key,
    required this.incomingCount,
    required this.outgoingCount,
    required this.onRefresh,
  });

  final int incomingCount;
  final int outgoingCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return KvSectionCard(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryMuted,
            foregroundColor: AppColors.primary,
            child: Icon(Icons.key_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Key requests', style: AppTextTheme.heading),
                const SizedBox(height: 4),
                Text(
                  '$incomingCount incoming • $outgoingCount outgoing',
                  style: AppTextTheme.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh keys',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
