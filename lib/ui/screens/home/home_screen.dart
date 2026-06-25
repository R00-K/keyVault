import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../infra/api/services/auth_service.dart';
import '../../routes/route_names.dart';
import '../../widgets/kv_section_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _selectedIndex = 0;

  static const _trustedContacts = [
    _TrustedContact(
      'Asha Rao',
      'QR verified',
      'Lunch keys are ready to exchange.',
      '12:42',
      2,
    ),
    _TrustedContact(
      'Daniel Kim',
      'NFC verified',
      'Key refreshed yesterday',
      '09:18',
      0,
    ),
    _TrustedContact(
      'Mira Patel',
      'Manual key verified',
      'No unread messages',
      'Yesterday',
      0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final displayName = user?.displayName?.isNotEmpty ?? false
        ? user!.displayName!
        : 'KeyVault user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('KeyVault', style: AppTextTheme.title),
        actions: [
          IconButton(
            tooltip: 'New contact',
            onPressed: _showNewContactOptions,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          PopupMenuButton<_HomeMenuAction>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleMenuAction(context, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _HomeMenuAction.settings,
                child: Text('Settings'),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.signOut,
                child: Text('Sign out'),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _ChatsView(contacts: _trustedContacts),
          _ProfileView(displayName: displayName, email: user?.email),
          _CallsView(contacts: _trustedContacts),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              tooltip: 'New contact',
              onPressed: _showNewContactOptions,
              child: const Icon(Icons.chat_outlined),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call),
            label: 'Calls',
          ),
        ],
      ),
    );
  }

  Future<void> _showNewContactOptions() async {
    final method = await showModalBottomSheet<_ContactAddMethod>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _NewContactSheet(),
    );

    if (!mounted || method == null) return;

    final message = switch (method) {
      _ContactAddMethod.qr => 'QR contact verification is coming next.',
      _ContactAddMethod.nfc => 'NFC contact verification is coming next.',
      _ContactAddMethod.manual => 'Manual key typing is coming next.',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    _HomeMenuAction action,
  ) async {
    switch (action) {
      case _HomeMenuAction.settings:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings screen is coming next.')),
        );
      case _HomeMenuAction.signOut:
        await AuthService.signOut();
        if (context.mounted) {
          context.go(RouteNames.login);
        }
    }
  }
}

class _ChatsView extends StatelessWidget {
  const _ChatsView({required this.contacts});

  final List<_TrustedContact> contacts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemBuilder: (context, index) => _ContactTile(contact: contacts[index]),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: contacts.length,
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.displayName, required this.email});

  final String displayName;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        KvSectionCard(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryMuted,
                foregroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: AppTextTheme.heading),
                    const SizedBox(height: 4),
                    Text(
                      email ?? 'No email linked',
                      style: AppTextTheme.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _InfoTile(
          icon: Icons.verified_user_outlined,
          title: 'Physical trust active',
          subtitle: 'Contacts are verified before secure messaging.',
        ),
        const SizedBox(height: 12),
        const _InfoTile(
          icon: Icons.lock_outline,
          title: 'Keys stay on this device',
          subtitle: 'Server-side contact keys are not stored.',
        ),
      ],
    );
  }
}

class _CallsView extends StatelessWidget {
  const _CallsView({required this.contacts});

  final List<_TrustedContact> contacts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemBuilder: (context, index) => _CallTile(contact: contacts[index]),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: contacts.length,
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final _TrustedContact contact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        context.push(RouteNames.chatFor(contact.name));
      },
      child: KvSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.primary,
              child: Icon(Icons.lock_person_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: AppTextTheme.heading,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(contact.time, style: AppTextTheme.caption),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          contact.messagePreview,
                          style: AppTextTheme.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        _UnreadBadge(count: contact.unreadCount),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(contact.verification, style: AppTextTheme.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.contact});

  final _TrustedContact contact;

  @override
  Widget build(BuildContext context) {
    return KvSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.surfaceVariant,
            foregroundColor: AppColors.primary,
            child: Icon(Icons.lock_person_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: AppTextTheme.heading,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.call_made,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Secure call • ${contact.time}',
                        style: AppTextTheme.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Call ${contact.name}',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Secure call with ${contact.name} is coming next.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.call_outlined),
          ),
        ],
      ),
    );
  }
}

class _NewContactSheet extends StatelessWidget {
  const _NewContactSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add contact', style: AppTextTheme.heading),
            const SizedBox(height: 12),
            _ContactMethodTile(
              icon: Icons.qr_code_2,
              title: 'By QR',
              subtitle: 'Scan a trusted key in person.',
              method: _ContactAddMethod.qr,
            ),
            _ContactMethodTile(
              icon: Icons.nfc_outlined,
              title: 'By NFC',
              subtitle: 'Tap phones to exchange keys.',
              method: _ContactAddMethod.nfc,
            ),
            _ContactMethodTile(
              icon: Icons.keyboard_outlined,
              title: 'By manual key',
              subtitle: 'Type or paste the contact key.',
              method: _ContactAddMethod.manual,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactMethodTile extends StatelessWidget {
  const _ContactMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.method,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _ContactAddMethod method;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => Navigator.of(context).pop(method),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return KvSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 14),
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
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.background,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _HomeMenuAction { settings, signOut }

enum _ContactAddMethod { qr, nfc, manual }

class _TrustedContact {
  const _TrustedContact(
    this.name,
    this.verification,
    this.messagePreview,
    this.time,
    this.unreadCount,
  );

  final String name;
  final String verification;
  final String messagePreview;
  final String time;
  final int unreadCount;
}
