import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_theme.dart';
import '../../../infra/api/services/auth_service.dart';
import '../../../notifications/notification_service.dart';
import '../../routes/route_names.dart';
import '../../widgets/kv_button.dart';
import '../../widgets/kv_logo.dart';
import '../../widgets/kv_page.dart';
import '../../widgets/kv_section_card.dart';
import '../../widgets/kv_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Enter your email and password.');
      return;
    }

    setState(() {
      _errorText = null;
      _loading = true;
    });

    try {
      await AuthService.signIn(email: email, password: password);
      final user = AuthService.currentUser;
      if (user != null) {
        await NotificationService.saveTokenToFirestore(user.uid);
      }
      if (mounted) {
        context.go(RouteNames.home);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = AuthService.errorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KvPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const KvLogo(iconSize: 64),
          const SizedBox(height: 36),
          const Text('Sign in', style: AppTextTheme.title),
          const SizedBox(height: 8),
          const Text(
            'Access your local vault and encrypted conversations.',
            style: AppTextTheme.bodyMuted,
          ),
          const SizedBox(height: 24),
          KvSectionCard(
            child: Column(
              children: [
                KvTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                KvTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorText!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                KvButton(
                  label: 'Sign in',
                  icon: Icons.login,
                  loading: _loading,
                  onPressed: _login,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KvButton(
            label: 'Create an account',
            icon: Icons.person_add_alt_1_outlined,
            variant: KvButtonVariant.secondary,
            onPressed: _loading ? null : () => context.go(RouteNames.register),
          ),
        ],
      ),
    );
  }
}
