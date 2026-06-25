import 'package:flutter/material.dart';

class KvPage extends StatelessWidget {
  const KvPage({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.appBar,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: SingleChildScrollView(padding: padding, child: child),
      ),
    );
  }
}
