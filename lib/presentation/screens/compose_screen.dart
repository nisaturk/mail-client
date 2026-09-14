import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../models/mail_account.dart';
import '../../repositories/api_client.dart';
import '../../repositories/mail_repository.dart';
import '../../state/mail_accounts_provider.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({
    super.key,
    this.initialTo,
    this.initialSubject,
    this.initialBody,
  });

  final String? initialTo;
  final String? initialSubject;
  final String? initialBody;

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _toCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _bodyCtrl;
  late final String _idempotencyKey;
  bool _reuseKeyForRetry = false;
  MailAccount? _selectedAccount;
  final List<_PickedFile> _attachments = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
    _toCtrl = TextEditingController(text: widget.initialTo ?? '');
    _subjectCtrl = TextEditingController(text: widget.initialSubject ?? '');
    _bodyCtrl = TextEditingController(text: widget.initialBody ?? '');
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  String get _title {
    final String s = widget.initialSubject ?? '';
    if (s.startsWith('Re:')) return 'Reply';
    if (s.startsWith('Fwd:')) return 'Forward';
    return 'New message';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final accountsState = ref.watch(mailAccountsProvider);
    final activeAccounts =
        accountsState.accounts.where((a) => a.isActive).toList();

    if (_selectedAccount == null && activeAccounts.isNotEmpty) {
      _selectedAccount = activeAccounts.first;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title),
        actions: [
          if (_sending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.send_outlined),
              tooltip: 'Send',
              onPressed: _send,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: DropdownButtonFormField<MailAccount>(
                isExpanded: true,
                initialValue: _selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                items: activeAccounts
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(
                            a.emailAddress,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAccount = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextFormField(
                controller: _toCtrl,
                decoration: const InputDecoration(
                  labelText: 'To',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            if (_attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Column(
                  children: [
                    for (final (index, f) in _attachments.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.insert_drive_file_outlined,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.basename(f.path),
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Remove attachment',
                              onPressed: () => setState(
                                () => _attachments.removeAt(index),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: TextFormField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  hintText: 'Write your message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sending ? null : _pickAttachment,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Attach'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;
    setState(() {
      for (final f in files) {
        if (f.path != null) {
          _attachments.add(_PickedFile(path: f.path!));
        }
      }
    });
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a sending account')),
      );
      return;
    }

    if (!_reuseKeyForRetry) {
      // A fresh logical send action gets a fresh idempotency key.
      _idempotencyKey = const Uuid().v4();
    } else {
      // Retrying the exact same send (same recipients/subject/body/attachments)
      // must reuse the original key so the backend replays, not resends.
      _reuseKeyForRetry = false;
    }

    setState(() => _sending = true);

    final sendResult = await sendMail(
      dio: ref.read(apiClientProvider).dio,
      accountId: _selectedAccount!.id,
      toAddress: _toCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      bodyText: _bodyCtrl.text.trim(),
      attachments: await _buildAttachments(),
      idempotencyKey: _idempotencyKey,
    );

    if (!mounted) return;
    setState(() => _sending = false);

    if (sendResult.sent) {
      final message = sendResult.sentCopySaved == false
          ? (sendResult.warning ?? 'Mail was sent but the sent copy could not be saved.')
          : 'Mail sent';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (sendResult.deliveryUncertain) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sending may have already started. Check your mailbox before '
            'sending again.',
          ),
        ),
      );
      return;
    }

    if (sendResult.retryable) {
      _reuseKeyForRetry = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sendResult.error ?? 'Failed to send mail'),
          action: SnackBarAction(label: 'Retry', onPressed: _send),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sendResult.error ?? 'Failed to send mail')),
    );
  }

  Future<List<MultipartFile>> _buildAttachments() async {
    final files = <MultipartFile>[];
    for (final f in _attachments) {
      files.add(await MultipartFile.fromFile(
        f.path,
        filename: p.basename(f.path),
      ));
    }
    return files;
  }
}

class _PickedFile {
  final String path;
  const _PickedFile({required this.path});
}