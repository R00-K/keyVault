import 'package:flutter/material.dart';

class KvButton extends StatelessWidget {
  const KvButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.variant = KvButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final KvButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : _ButtonContent(label: label, icon: icon);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: variant == KvButtonVariant.primary
          ? ElevatedButton(onPressed: loading ? null : onPressed, child: child)
          : OutlinedButton(onPressed: loading ? null : onPressed, child: child),
    );
  }
}

enum KvButtonVariant { primary, secondary }

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Text(label);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
