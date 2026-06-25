import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_theme.dart';
import '../../../infra/api/services/auth_service.dart';
import '../../routes/route_names.dart';
import '../../widgets/kv_button.dart';
import '../../widgets/kv_page.dart';
import '../../widgets/kv_section_card.dart';
import '../../widgets/kv_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  Future<void> _register() async {
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
      debugPrint('[RegisterScreen] Creating Firebase Auth user for $email');
      await AuthService.register(email: email, password: password);
      if (mounted) {
        debugPrint('[RegisterScreen] Firebase Auth success. Opening profile.');
        context.go(RouteNames.completeProfile);
      }
    } catch (error) {
      debugPrint('[RegisterScreen] Firebase Auth failed: $error');
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
      appBar: AppBar(title: const Text('Create account')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Set up KeyVault', style: AppTextTheme.title),
          const SizedBox(height: 8),
          const Text(
            'Your account identifies you. Contact keys are exchanged later through physical trust.',
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
                  onSubmitted: (_) => _register(),
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
                  label: 'Create account',
                  icon: Icons.verified_user_outlined,
                  loading: _loading,
                  onPressed: _register,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KvButton(
            label: 'Back to sign in',
            icon: Icons.arrow_back,
            variant: KvButtonVariant.secondary,
            onPressed: _loading ? null : () => context.go(RouteNames.login),
          ),
        ],
      ),
    );
  }
}
