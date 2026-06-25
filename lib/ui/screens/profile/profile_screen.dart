import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../infra/api/models/user_model.dart';
import '../../../infra/api/services/auth_service.dart';
import '../../../infra/api/services/user_service.dart';
import '../../routes/route_names.dart';
import '../../widgets/kv_button.dart';
import '../../widgets/kv_section_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _profileFuture = _loadProfile();
    }
  }

  Future<UserModel?> _loadProfile() async {
    final firebaseUser = AuthService.currentUser;
    if (firebaseUser == null) {
      debugPrint('[ProfileScreen] No Firebase user found.');
      return null;
    }

    debugPrint('[ProfileScreen] Fetching Firestore profile.');
    final profile = await UserService.getUser(firebaseUser.uid);
    debugPrint(
      profile == null
          ? '[ProfileScreen] No Firestore profile document found.'
          : '[ProfileScreen] Firestore profile loaded.',
    );

    return profile;
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ProfileLoadingView();
        }

        if (snapshot.hasError) {
          debugPrint('[ProfileScreen] Profile fetch failed: ${snapshot.error}');
          return _ProfileErrorView(onRetry: _refreshProfile);
        }

        final profile = snapshot.data;
        if (profile == null) {
          return const _MissingProfileView();
        }

        return _ProfileContent(profile: profile, onRefresh: _refreshProfile);
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile, required this.onRefresh});

  final UserModel profile;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          KvSectionCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primaryMuted,
                  foregroundColor: AppColors.primary,
                  backgroundImage: profile.photoUrl == null
                      ? null
                      : NetworkImage(profile.photoUrl!),
                  child: profile.photoUrl == null
                      ? const Icon(Icons.person, size: 42)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile.displayName,
                  style: AppTextTheme.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  profile.email,
                  style: AppTextTheme.bodyMuted,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KvSectionCard(
            child: Column(
              children: [
                _ProfileInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: profile.phoneNumber,
                ),
                const _InfoDivider(),
                _ProfileInfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Date of birth',
                  value: _formatDate(profile.dateOfBirth.toDate()),
                ),
                const _InfoDivider(),
                _ProfileInfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Account',
                  value: profile.isOnline ? 'Active now' : 'Active',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const KvSectionCard(
            child: Column(
              children: [
                _SecurityNote(
                  icon: Icons.lock_outline,
                  title: 'Private by design',
                  subtitle: 'Internal account identifiers are hidden here.',
                ),
                SizedBox(height: 14),
                _SecurityNote(
                  icon: Icons.handshake_outlined,
                  title: 'Trusted contacts',
                  subtitle:
                      'Secure messaging starts after contact verification.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.surfaceVariant,
          foregroundColor: AppColors.primary,
          child: Icon(icon, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextTheme.caption),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? 'Not provided' : value,
                style: AppTextTheme.body,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextTheme.heading),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextTheme.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        KvSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.warning,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Profile could not be loaded',
                style: AppTextTheme.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection or Firestore permissions, then try again.',
                style: AppTextTheme.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              KvButton(
                label: 'Try again',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissingProfileView extends StatelessWidget {
  const _MissingProfileView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        KvSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.person_search_outlined,
                color: AppColors.primary,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Complete your profile',
                style: AppTextTheme.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your profile details are needed before secure contacts can recognize you.',
                style: AppTextTheme.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              KvButton(
                label: 'Complete profile',
                icon: Icons.arrow_forward,
                onPressed: () => context.go(RouteNames.completeProfile),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
