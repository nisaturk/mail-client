import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../state/auth_provider.dart';
import '../../state/mail_provider.dart';
import 'admin_screen.dart';
import 'compose_screen.dart';
import 'mail_accounts_screen.dart';
import 'mail_list_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('FlapMail')),
      drawer: _MailDrawer(isAdmin: auth.isAdmin),
      body: const Center(child: Text('Select a folder from the drawer')),
    );
  }
}

class _MailDrawer extends ConsumerWidget {
  final bool isAdmin;

  const _MailDrawer({required this.isAdmin});

  void _openMailList(
    BuildContext context, {
    required String title,
    String? accountId,
    MailFolderType? folderType,
  }) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MailListScreen(
          title: title,
          accountId: accountId,
          folderType: folderType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mailState = ref.watch(mailListProvider);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'FlapMail',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const _SectionHeader('Unified'),
            _BadgeListTile(
              icon: Icons.inbox,
              title: 'Inbox',
              badgeCount: mailState.unreadCountAll(MailFolderType.inbox),
              onTap: () => _openMailList(
                context,
                title: 'Unified Inbox',
                folderType: MailFolderType.inbox,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Sent'),
              onTap: () => _openMailList(
                context,
                title: 'Unified Sent',
                folderType: MailFolderType.sent,
              ),
            ),
            const Divider(),
            const _SectionHeader('Accounts'),
            _AccountExpansionTile(
              email: 'ahmet@tekyazilim.com',
              accountId: '1',
              mailState: mailState,
              openMailList: _openMailList,
            ),
            _AccountExpansionTile(
              email: 'destek@tekyazilim.com',
              accountId: '2',
              mailState: mailState,
              openMailList: _openMailList,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add Mail Account'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MailAccountsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Compose Mail'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComposeScreen()),
                );
              },
            ),
            if (isAdmin) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin Panel'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _BadgeListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int badgeCount;
  final VoidCallback onTap;

  const _BadgeListTile({
    required this.icon,
    required this.title,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _AccountExpansionTile extends StatelessWidget {
  final String email;
  final String accountId;
  final MailListState mailState;
  final void Function(BuildContext context, {required String title, String? accountId, MailFolderType? folderType}) openMailList;

  const _AccountExpansionTile({
    required this.email,
    required this.accountId,
    required this.mailState,
    required this.openMailList,
  });

  @override
  Widget build(BuildContext context) {
    final unread = mailState.unreadCountForAccount(accountId);
    return ExpansionTile(
      leading: const Icon(Icons.mail_outline),
      title: Text(email),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unread',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.only(left: 72),
          leading: const Icon(Icons.inbox, size: 20),
          title: const Text('Inbox', style: TextStyle(fontSize: 14)),
          onTap: () => openMailList(
            context,
            title: email,
            accountId: accountId,
            folderType: MailFolderType.inbox,
          ),
        ),
        ListTile(
          contentPadding: const EdgeInsets.only(left: 72),
          leading: const Icon(Icons.send, size: 20),
          title: const Text('Sent', style: TextStyle(fontSize: 14)),
          onTap: () => openMailList(
            context,
            title: email,
            accountId: accountId,
            folderType: MailFolderType.sent,
          ),
        ),
      ],
    );
  }
}
