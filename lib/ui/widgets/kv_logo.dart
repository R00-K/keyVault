import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_theme.dart';

class KvLogo extends StatelessWidget {
  const KvLogo({super.key, this.iconSize = 72});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.enhanced_encryption_outlined,
            color: AppColors.primary,
            size: iconSize * 0.52,
          ),
        ),
        const SizedBox(height: 18),
        const Text('KeyVault', style: AppTextTheme.display),
        const SizedBox(height: 8),
        const Text('Physical Trust Messenger', style: AppTextTheme.caption),
      ],
    );
  }
}
