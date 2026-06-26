import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_theme.dart';
import '../../../../infra/api/models/key_request_model.dart';
import '../../../widgets/kv_section_card.dart';
import 'key_request_tile.dart';

enum KeyRequestDirection { incoming, outgoing }

class KeyRequestSection extends StatelessWidget {
  const KeyRequestSection({
    super.key,
    required this.title,
    required this.emptyText,
    required this.requests,
    required this.direction,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
  });

  final String title;
  final String emptyText;
  final List<KeyRequestModel> requests;
  final KeyRequestDirection direction;
  final ValueChanged<KeyRequestModel>? onAccept;
  final ValueChanged<KeyRequestModel>? onReject;
  final ValueChanged<KeyRequestModel>? onCancel;

  @override
  Widget build(BuildContext context) {
    return KvSectionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextTheme.heading),
          const SizedBox(height: 10),
          if (requests.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(emptyText, style: AppTextTheme.bodyMuted),
            )
          else
            for (final request in requests) ...[
              KeyRequestTile(
                request: request,
                direction: direction,
                onAccept: onAccept == null ? null : () => onAccept!(request),
                onReject: onReject == null ? null : () => onReject!(request),
                onCancel: onCancel == null ? null : () => onCancel!(request),
              ),
              if (request != requests.last) const Divider(height: 18),
            ],
        ],
      ),
    );
  }
}
