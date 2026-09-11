import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/mail_summary.dart';
import '../../models/mail_detail.dart';
import '../../models/attachment.dart';
import '../../state/mail_provider.dart';
import 'compose_screen.dart';

class MailDetailScreen extends ConsumerStatefulWidget {
  final String mailId;
  final MailSummary? mail;

  const MailDetailScreen({super.key, required this.mailId, this.mail});

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
    final detail = await loadMailDetail(widget.mailId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
    if (detail != null && !detail.isRead) {
      ref.read(mailListProvider.notifier).markAsRead(widget.mailId);
      await markMailAsRead(widget.mailId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
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
        title: Text(
          detail.subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: () => _openCompose(
              context,
              to: detail.fromAddress,
              subject: detail.subject,
              quotedBody: detail.bodyText.isNotEmpty ? detail.bodyText : null,
              prefix: 'Re',
            ),
            icon: const Icon(Icons.reply),
            tooltip: 'Reply',
          ),
          IconButton(
            onPressed: () => _openCompose(
              context,
              subject: detail.subject,
              quotedBody: detail.bodyText.isNotEmpty ? detail.bodyText : null,
              prefix: 'Fwd',
            ),
            icon: const Icon(Icons.forward),
            tooltip: 'Forward',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        sender.isNotEmpty
                            ? sender[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sender,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            detail.fromAddress,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'To: ${detail.toAddress}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            _AttachmentList(attachments: detail.attachments),
          ],
        ],
      ),
    );
  }
}

class _HtmlBody extends StatefulWidget {
  final String html;
  const _HtmlBody({required this.html});

  @override
  State<_HtmlBody> createState() => _HtmlBodyState();
}

class _HtmlBodyState extends State<_HtmlBody> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_wrapHtml(widget.html));
  }

  String _wrapHtml(String body) => '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
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

class _AttachmentList extends StatelessWidget {
  final List<Attachment> attachments;
  const _AttachmentList({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final a = attachments[index];
          return _AttachmentChip(attachment: a);
        },
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final Attachment attachment;
  const _AttachmentChip({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final icon = _iconForType(attachment.contentType);
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            attachment.fileName,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            attachment.sizeLabel,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading ${attachment.fileName}')),
        );
      },
    );
  }

  IconData _iconForType(String contentType) {
    if (contentType.contains('pdf')) return Icons.picture_as_pdf;
    if (contentType.contains('image')) return Icons.image;
    if (contentType.contains('spreadsheet') || contentType.contains('excel') || contentType.contains('xlsx')) {
      return Icons.table_chart;
    }
    if (contentType.contains('word') || contentType.contains('document')) {
      return Icons.description;
    }
    return Icons.attach_file;
  }
}
