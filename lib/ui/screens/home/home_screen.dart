import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../crypto/secure_key_storage.dart';
import '../../../infra/api/services/auth_service.dart';
import '../../../infra/api/services/contact_service.dart';
import '../../routes/route_names.dart';
import '../keys/key_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _selectedIndex = 0;
  var _keysRefreshToken = 0;
  var _profileRefreshToken = 0;
  var _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    await ContactService.loadContacts();
    final hasContacts = ContactService.count > 0 ||
        await SecureKeyStorage.hasTrustedContact();
    if (!mounted) return;
    setState(() {
      if (!hasContacts) {
        _selectedIndex = 1;
      }
      _initialLoadDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KeyVault', style: AppTextTheme.title),
        actions: [
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
          _buildChatsView(),
          KeyScreen(refreshToken: _keysRefreshToken),
          ProfileScreen(refreshToken: _profileRefreshToken),
          _CallsView(contacts: ContactService.contacts),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 1) {
              _keysRefreshToken++;
            }
            if (index == 2) {
              _profileRefreshToken++;
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.key_outlined),
            selectedIcon: Icon(Icons.key),
            label: 'Keys',
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

  Widget _buildChatsView() {
    if (!_initialLoadDone) {
      return const Center(child: CircularProgressIndicator());
    }

    final contacts = ContactService.contacts;

    if (contacts.isEmpty) {
      return _EmptyChatsView(
        onGoToKeys: () {
          setState(() {
            _selectedIndex = 1;
            _keysRefreshToken++;
          });
        },
      );
    }

    return _ChatsView(contacts: contacts, onChatTap: _openChat);
  }

  void _openChat(TrustedContact contact) {
    context.push(
      RouteNames.chatFor(contact.name),
      extra: <String, dynamic>{
        'sessionId': contact.sessionId,
        'to': contact.to,
        'peerPublicKey': contact.peerPublicKey,
        'from': AuthService.currentUser?.uid ?? '',
      },
    );
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
        break;
      case _HomeMenuAction.signOut:
        await AuthService.signOut();
        if (context.mounted) {
          context.go(RouteNames.login);
        }
    }
  }
}

class _EmptyChatsView extends StatelessWidget {
  const _EmptyChatsView({required this.onGoToKeys});

  final VoidCallback onGoToKeys;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.lock_person_outlined,
          size: 72,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'No trusted contacts yet',
          style: AppTextTheme.heading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Establish trust with a contact first to start a secure chat.',
          style: AppTextTheme.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: onGoToKeys,
          icon: const Icon(Icons.key_outlined),
          label: const Text('Go to Keys'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatsView extends StatelessWidget {
  const _ChatsView({required this.contacts, required this.onChatTap});

  final List<TrustedContact> contacts;
  final void Function(TrustedContact) onChatTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemBuilder: (context, index) => _ContactTile(
        contact: contacts[index],
        onTap: () => onChatTap(contacts[index]),
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: contacts.length,
    );
  }
}

class _CallsView extends StatelessWidget {
  const _CallsView({required this.contacts});

  final List<TrustedContact> contacts;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const Center(
        child: Text(
          'No contacts yet',
          style: AppTextTheme.bodyMuted,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemBuilder: (context, index) => _CallTile(contact: contacts[index]),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: contacts.length,
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, this.onTap});

  final TrustedContact contact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(contact.name),
        subtitle: Text(
          contact.unreadCount > 0
              ? '${contact.verification} • ${contact.messagePreview} • ${contact.unreadCount} unread'
              : '${contact.verification} • ${contact.messagePreview}',
        ),
        trailing: Text(contact.time),
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.contact});

  final TrustedContact contact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(contact.name),
        subtitle: Text('Secure call • ${contact.time}'),
        trailing: const Icon(Icons.call_outlined),
      ),
    );
  }
}

enum _HomeMenuAction { settings, signOut }
