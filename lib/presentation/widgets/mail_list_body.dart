import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../state/mail_provider.dart';
import '../screens/mail_detail_screen.dart';
import 'mail_list_item.dart';

/// The mail list body with loading / empty / error states baked in.
///
/// The parent controls which account/folder is shown and resets this widget
/// via a new [Key] whenever the selection changes.
class MailListBody extends ConsumerStatefulWidget {
  const MailListBody({super.key, this.accountId, this.folder});

  final String? accountId;
  final MailFolderType? folder;

  @override
  ConsumerState<MailListBody> createState() => _MailListBodyState();
}

class _MailListBodyState extends ConsumerState<MailListBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() {
    return ref.read(mailListProvider.notifier).load(
          accountId: widget.accountId,
          folderType: widget.folder,
        );
  }

  @override
  Widget build(BuildContext context) {
    final MailListState state = ref.watch(mailListProvider);

    if (state.isLoading && state.mails.isEmpty) {
      return const MailListSkeleton();
    }
    if (state.error != null && state.mails.isEmpty) {
      return ErrorMailState(onRetry: _load);
    }
    if (state.mails.isEmpty) {
      return EmptyMailState(folder: widget.folder);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.mails.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final mail = state.mails[index];
          return MailListItem(
            mail: mail,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MailDetailScreen(mailId: mail.id, mail: mail),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Intentional empty state shown when a folder has no mail.
class EmptyMailState extends StatelessWidget {
  const EmptyMailState({super.key, this.folder, this.title, this.message});

  final MailFolderType? folder;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final bool isSent = folder == MailFolderType.sent;
    return _MailStateView(
      icon: isSent ? Icons.send_outlined : Icons.inbox_outlined,
      title: title ?? (isSent ? 'No sent messages' : 'No messages'),
      message: message ??
          (isSent
              ? "You haven't sent any messages yet."
              : 'Your mailbox is empty.'),
    );
  }
}

/// Intentional error state with a retry action.
class ErrorMailState extends StatelessWidget {
  const ErrorMailState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _MailStateView(
      icon: Icons.cloud_off_outlined,
      title: "Couldn't load your messages",
      message: 'Check your connection and try again.',
      action: FilledButton.tonalIcon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      ),
    );
  }
}

class _MailStateView extends StatelessWidget {
  const _MailStateView({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Lightweight placeholder rows shown while mail is loading.
class MailListSkeleton extends StatelessWidget {
  const MailListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final Color bar = Theme.of(context).colorScheme.surfaceContainerHigh;

    Widget circle() => Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: bar, shape: BoxShape.circle),
        );

    Widget line([double widthFactor = 1.0]) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: bar,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      separatorBuilder: (_, _) => const Divider(height: 24),
      itemBuilder: (_, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          circle(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line(0.7),
                const SizedBox(height: 8),
                line(),
                const SizedBox(height: 8),
                line(0.5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}