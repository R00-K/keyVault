import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_theme.dart';
import '../../../infra/api/services/auth_service.dart';
import '../../routes/route_names.dart';
import '../keys/key_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _selectedIndex = 1;
  var _keysRefreshToken = 0;
  var _profileRefreshToken = 0;

  static const _trustedContacts = [
    _TrustedContact(
      'Diyaaa',
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
          _ChatsView(contacts: _trustedContacts),
          KeyScreen(refreshToken: _keysRefreshToken),
          ProfileScreen(refreshToken: _profileRefreshToken),
          _CallsView(contacts: _trustedContacts),
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
    return Card(
      child: ListTile(
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

  final _TrustedContact contact;

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
