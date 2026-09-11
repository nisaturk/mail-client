import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../models/enums.dart';
import '../../state/admin_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  UserStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final filtered = _filter == null
        ? state.users
        : state.users.where((u) => u.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserDialog(context, ref),
        child: const Icon(Icons.person_add_outlined),
      ),
      body: Column(
        children: [
          _StatusFilter(
            selected: _filter,
            onChanged: (v) => setState(() => _filter = v),
            counts: _countByStatus(state.users),
          ),
          Expanded(
            child: state.isLoading && state.users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _UserTile(user: filtered[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Map<UserStatus, int> _countByStatus(List<User> users) {
    return {
      for (final s in UserStatus.values)
        s: users.where((u) => u.status == s).length,
    };
  }

  void _showCreateUserDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create User'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              ref.read(adminProvider.notifier).createUser(
                    emailCtrl.text.trim(),
                    nameCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final UserStatus? selected;
  final ValueChanged<UserStatus?> onChanged;
  final Map<UserStatus, int> counts;

  const _StatusFilter({
    required this.selected,
    required this.onChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            count: counts.values.fold(0, (a, b) => a + b),
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...UserStatus.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: s.name[0].toUpperCase() + s.name.substring(1),
                  count: counts[s] ?? 0,
                  selected: selected == s,
                  onTap: () => onChanged(s),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('$label ($count)'),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final User user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(adminProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : user.email[0].toUpperCase(),
          ),
        ),
        title: Text(user.displayName.isNotEmpty ? user.displayName : user.email),
        subtitle: Row(
          children: [
            Text(user.email, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            _StatusBadge(status: user.status),
            if (user.role == UserRole.admin) ...[
              const SizedBox(width: 4),
              const _AdminBadge(),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAction(context, ref, action, notifier),
          itemBuilder: (_) => _buildMenuItems(),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    final items = <PopupMenuEntry<String>>[];

    if (user.status == UserStatus.pending) {
      items.add(const PopupMenuItem(
        value: 'approve',
        child: ListTile(
          leading: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text('Approve'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }

    if (user.status == UserStatus.active) {
      items.add(const PopupMenuItem(
        value: 'disable',
        child: ListTile(
          leading: Icon(Icons.block, color: Colors.orange),
          title: Text('Disable'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }

    if (user.status == UserStatus.disabled) {
      items.add(const PopupMenuItem(
        value: 'enable',
        child: ListTile(
          leading: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text('Enable'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }

    items.add(const PopupMenuItem(
      value: 'reset_password',
      child: ListTile(
        leading: Icon(Icons.lock_reset),
        title: Text('Reset Password'),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ));

    return items;
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    AdminNotifier notifier,
  ) {
    switch (action) {
      case 'approve':
        notifier.approve(user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.email} approved')),
        );
      case 'disable':
        notifier.disable(user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.email} disabled')),
        );
      case 'enable':
        notifier.enable(user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.email} enabled')),
        );
      case 'reset_password':
        _showResetPasswordDialog(context, ref, notifier);
    }
  }

  void _showResetPasswordDialog(
    BuildContext context,
    WidgetRef ref,
    AdminNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send a password reset email to ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              notifier.resetPassword(user.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password reset email sent to ${user.email}'),
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final UserStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      UserStatus.active => (Colors.green, 'Active'),
      UserStatus.pending => (Colors.orange, 'Pending'),
      UserStatus.disabled => (Colors.red, 'Disabled'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color.shade700),
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Admin',
        style: TextStyle(fontSize: 10, color: Colors.purple.shade700),
      ),
    );
  }
}
