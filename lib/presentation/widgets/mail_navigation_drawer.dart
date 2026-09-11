import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../models/mail_account.dart';
import '../../state/auth_provider.dart';
import '../../state/mail_accounts_provider.dart';
import '../../state/mail_provider.dart';
import '../screens/mail_accounts_screen.dart';

/// Signature for switching the visible mail folder in the parent screen.
typedef FolderSelection = void Function({
  required String title,
  String? accountId,
  MailFolderType? folder,
});

/// The app navigation drawer: mail folders, accounts and other actions.
///
/// Accounts come from [mailAccountsProvider] (mock data during development).
class MailNavigationDrawer extends ConsumerWidget {
  const MailNavigationDrawer({super.key, required this.onSelectFolder});

  final FolderSelection onSelectFolder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MailListState mailState = ref.watch(mailListProvider);
    final List<MailAccount> accounts =
        ref.watch(mailAccountsProvider).accounts.where((a) => a.isActive).toList();

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'FlapMail',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Company email',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const _DrawerSection('MAIL'),
            _DrawerNavTile(
              icon: Icons.inbox_outlined,
              label: 'Inbox',
              badge: mailState.unreadCountAll(MailFolderType.inbox),
              onTap: () => _selectFolder(
                context,
                title: 'Inbox',
                folder: MailFolderType.inbox,
              ),
            ),
            _DrawerNavTile(
              icon: Icons.send_outlined,
              label: 'Sent',
              badge: mailState.unreadCountAll(MailFolderType.sent),
              onTap: () => _selectFolder(
                context,
                title: 'Sent',
                folder: MailFolderType.sent,
              ),
            ),
            if (accounts.isNotEmpty) ...[
              const _DrawerSection('ACCOUNTS'),
              ...accounts.map(
                (account) => _AccountTile(
                  account: account,
                  unread: mailState.unreadCountForAccount(account.id),
                  onSelect: (title, folder) => _selectFolder(
                    context,
                    title: title,
                    accountId: account.id,
                    folder: folder,
                  ),
                ),
              ),
            ],
            const _DrawerSection('OTHER'),
            _DrawerNavTile(
              icon: Icons.account_box_outlined,
              label: 'Mail accounts',
              onTap: () => _openScreen(
                context,
                const MailAccountsScreen(),
              ),
            ),
            _DrawerNavTile(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () {
                ref.read(authProvider.notifier).logout();
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectFolder(
    BuildContext context, {
    required String title,
    String? accountId,
    MailFolderType? folder,
  }) {
    Navigator.pop(context);
    onSelectFolder(
      title: title,
      accountId: accountId,
      folder: folder,
    );
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    this.badge = 0,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: badge > 0 ? _BadgeCount(count: badge) : null,
      onTap: onTap,
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.unread,
    required this.onSelect,
  });

  final MailAccount account;
  final int unread;
  final void Function(String title, MailFolderType folder) onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ExpansionTile(
      leading: const Icon(Icons.alternate_email),
      title: Text(
        account.emailAddress,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: unread > 0 ? Text('$unread unread') : null,
      childrenPadding: const EdgeInsets.only(left: 56),
      children: [
        _FolderTile(
          icon: Icons.inbox_outlined,
          label: 'Inbox',
          onTap: () => onSelect(account.emailAddress, MailFolderType.inbox),
        ),
        _FolderTile(
          icon: Icons.send_outlined,
          label: 'Sent',
          onTap: () => onSelect(account.emailAddress, MailFolderType.sent),
        ),
      ],
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 64),
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}

class _BadgeCount extends StatelessWidget {
  const _BadgeCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}