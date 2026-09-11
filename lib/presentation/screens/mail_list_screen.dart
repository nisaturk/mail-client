import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/mail_summary.dart';
import '../../models/enums.dart';
import '../../state/mail_provider.dart';
import 'mail_detail_screen.dart';

class MailListScreen extends ConsumerStatefulWidget {
  final String? title;
  final String? accountId;
  final MailFolderType? folderType;

  const MailListScreen({
    super.key,
    this.title,
    this.accountId,
    this.folderType,
  });

  @override
  ConsumerState<MailListScreen> createState() => _MailListScreenState();
}

class _MailListScreenState extends ConsumerState<MailListScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    ref.read(mailListProvider.notifier).load(
          accountId: widget.accountId,
          folderType: widget.folderType,
        );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mailListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                ),
                onChanged: (q) => ref.read(mailListProvider.notifier).search(
                      accountId: widget.accountId,
                      folderType: widget.folderType,
                      query: q,
                    ),
              )
            : Text(widget.title ?? 'Inbox'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  ref.read(mailListProvider.notifier).search(
                        accountId: widget.accountId,
                        folderType: widget.folderType,
                        query: '',
                      );
                }
              });
            },
            icon: Icon(_showSearch ? Icons.close : Icons.search),
          ),
        ],
      ),
      body: state.isLoading && state.mails.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.mails.isEmpty
              ? const Center(child: Text('No messages'))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(mailListProvider.notifier).load(
                            accountId: widget.accountId,
                            folderType: widget.folderType,
                          ),
                  child: ListView.separated(
                    itemCount: state.mails.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _MailTile(mail: state.mails[index]);
                    },
                  ),
                ),
    );
  }
}

class _MailTile extends StatelessWidget {
  final MailSummary mail;
  const _MailTile({required this.mail});

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(mail.receivedAt);
    final sender = mail.fromDisplayName.isNotEmpty
        ? mail.fromDisplayName
        : mail.fromAddress;

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MailDetailScreen(mailId: mail.id, mail: mail),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: mail.isRead
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          sender.isNotEmpty ? sender[0].toUpperCase() : '?',
          style: TextStyle(
            color: mail.isRead
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        sender,
        style: TextStyle(
          fontWeight: mail.isRead ? FontWeight.normal : FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              mail.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: mail.isRead ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
          if (mail.hasAttachments) ...[
            const SizedBox(width: 4),
            Icon(Icons.attach_file, size: 14, color: Colors.grey.shade500),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 12,
              color: mail.isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          if (!mail.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      isThreeLine: false,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays < 1) {
      return DateFormat.Hm().format(dt);
    }
    if (now.difference(dt).inDays < 7) {
      return DateFormat.E().format(dt);
    }
    return DateFormat('d MMM').format(dt);
  }
}
