import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/attachment.dart';
import '../../models/mail_detail.dart';
import '../../models/mail_summary.dart';
import '../../repositories/api_client.dart';
import '../../repositories/mail_repository.dart';
import '../../state/mail_provider.dart';
import '../widgets/attachment_item.dart';
import 'compose_screen.dart';

class MailDetailScreen extends ConsumerStatefulWidget {
  const MailDetailScreen({super.key, required this.mailId, this.mail});

  final String mailId;
  final MailSummary? mail;

  @override
  ConsumerState<MailDetailScreen> createState() => _MailDetailScreenState();
}

class _MailDetailScreenState extends ConsumerState<MailDetailScreen> {
  MailDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _openCompose(
    BuildContext context, {
    String? to,
    String? subject,
    String? quotedBody,
    required String prefix,
  }) {
    final quotedSubject = (subject != null && subject.startsWith(prefix))
        ? subject
        : '$prefix: ${subject ?? ''}';
    final body = quotedBody != null
        ? '\n\n--- Original Message ---\n$quotedBody'
        : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposeScreen(
          initialTo: to,
          initialSubject: quotedSubject,
          initialBody: body,
        ),
      ),
    );
  }

  Future<void> _loadDetail() async {
    MailDetail? detail;
    try {
      detail = await ref
          .read(mailListProvider.notifier)
          .fetchDetail(widget.mailId);
    } catch (_) {
      detail = null;
    }
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
    if (detail != null && !detail.isRead) {
      ref.read(mailListProvider.notifier).markAsRead(widget.mailId);
    }
  }

  void _toggleRead(bool read) {
    final MailListNotifier notifier = ref.read(mailListProvider.notifier);
    read ? notifier.markAsRead(widget.mailId) : notifier.markAsUnread(widget.mailId);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Message')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Message not found')),
      );
    }

    final sender = detail.fromDisplayName.isNotEmpty
        ? detail.fromDisplayName
        : detail.fromAddress;
    final dateStr = widget.mail != null
        ? DateFormat('d MMM yyyy, HH:mm').format(widget.mail!.receivedAt)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'unread') _toggleRead(false);
              if (value == 'read') _toggleRead(true);
            },
            itemBuilder: (_) => [
              if (detail.isRead)
                PopupMenuItem(
                  value: 'unread',
                  child: _MenuRow(
                    icon: Icons.mark_email_read_outlined,
                    label: 'Mark as unread',
                  ),
                )
              else
                PopupMenuItem(
                  value: 'read',
                  child: _MenuRow(
                    icon: Icons.drafts_outlined,
                    label: 'Mark as read',
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _MessageHeader(detail: detail, sender: sender, dateStr: dateStr),
          const Divider(height: 1),
          Expanded(
            child: detail.bodyHtml.isNotEmpty
                ? _HtmlBody(html: detail.bodyHtml)
                : detail.bodyText.isNotEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Text(detail.bodyText),
                      )
                    : const Center(child: Text('No content')),
          ),
          if (detail.attachments.isNotEmpty) ...[
            const Divider(height: 1),
            _AttachmentBar(attachments: detail.attachments, mailId: detail.id),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _openCompose(
                    context,
                    to: detail.fromAddress,
                    subject: detail.subject,
                    quotedBody:
                        detail.bodyText.isNotEmpty ? detail.bodyText : null,
                    prefix: 'Re',
                  ),
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('Reply'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openCompose(
                    context,
                    subject: detail.subject,
                    quotedBody:
                        detail.bodyText.isNotEmpty ? detail.bodyText : null,
                    prefix: 'Fwd',
                  ),
                  icon: const Icon(Icons.forward, size: 18),
                  label: const Text('Forward'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageHeader extends StatelessWidget {
  const _MessageHeader({
    required this.detail,
    required this.sender,
    required this.dateStr,
  });

  final MailDetail detail;
  final String sender;
  final String dateStr;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.subject,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  sender.isNotEmpty ? sender[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sender,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      detail.fromAddress,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'To: ${detail.toAddress}',
            style:
                theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          if (dateStr.isNotEmpty)
            Text(
              dateStr,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _AttachmentBar extends ConsumerWidget {
  const _AttachmentBar({required this.attachments, required this.mailId});

  final List<Attachment> attachments;
  final String mailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attachments',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final attachment = attachments[index];
                return AttachmentItem(
                  width: 230,
                  attachment: attachment,
                  onTap: () => _download(context, ref, attachment),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    Attachment attachment,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Downloading ${attachment.fileName}')),
    );
    final String? savedPath;
    try {
      savedPath = await downloadAttachment(
        dio: ref.read(apiClientProvider).dio,
        mailId: mailId,
        attachmentId: attachment.id,
        fileName: attachment.fileName,
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to download attachment')),
      );
      return;
    }
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    if (savedPath == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Attachment not found')),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Saved ${attachment.fileName}')),
    );
    OpenFilex.open(savedPath);
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

class _HtmlBody extends StatefulWidget {
  const _HtmlBody({required this.html});

  final String html;

  @override
  State<_HtmlBody> createState() => _HtmlBodyState();
}

class _HtmlBodyState extends State<_HtmlBody> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) async {
          if (request.isMainFrame) {
            final uri = Uri.tryParse(request.url);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadHtmlString(_wrapHtml(widget.html));
  }

  String _wrapHtml(String body) => '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="Content-Security-Policy"
        content="default-src 'none'; img-src 'data:'; style-src 'unsafe-inline';">
      <style>
        body { font-family: sans-serif; padding: 16px; margin: 0; }
        img { max-width: 100%; height: auto; }
      </style>
    </head>
    <body>$body</body>
    </html>
  ''';

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}