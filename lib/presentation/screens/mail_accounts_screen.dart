import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mail_account.dart';
import '../../state/mail_accounts_provider.dart';
import 'add_edit_mail_account_screen.dart';

class MailAccountsScreen extends ConsumerWidget {
  const MailAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mailAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mail Accounts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditMailAccountScreen(),
            ),
          );
          if (result == true) {
            ref.read(mailAccountsProvider.notifier).load();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: state.isLoading && state.accounts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.accounts.isEmpty
              ? const Center(child: Text('No accounts connected'))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: state.accounts.length,
                  itemBuilder: (context, index) {
                    return _AccountCard(account: state.accounts[index]);
                  },
                ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final MailAccount account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mail_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.emailAddress,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (account.displayName.isNotEmpty)
                        Text(
                          account.displayName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                _StatusBadge(isActive: account.isActive),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'IMAP: ${account.imapHost}:${account.imapPort}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  'SMTP: ${account.smtpHost}:${account.smtpPort}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TestButton(accountId: account.id),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditMailAccountScreen(
                          account: account,
                        ),
                      ),
                    );
                    ref.read(mailAccountsProvider.notifier).load();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Remove ${account.emailAddress}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(mailAccountsProvider.notifier).delete(account.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TestButton extends ConsumerStatefulWidget {
  final String accountId;
  const _TestButton({required this.accountId});

  @override
  ConsumerState<_TestButton> createState() => _TestButtonState();
}

class _TestButtonState extends ConsumerState<_TestButton> {
  bool _testing = false;

  Future<void> _test() async {
    setState(() => _testing = true);
    final success = await ref
        .read(mailAccountsProvider.notifier)
        .testConnection(widget.accountId);
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Connection successful' : 'Connection failed'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _testing ? null : _test,
      icon: _testing
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wifi_find, size: 18),
      label: const Text('Test'),
    );
  }
}
