import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../models/mail_account.dart';
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
  MailAccount? _selectedAccount;
  final List<_PickedFile> _attachments = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
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

    setState(() => _sending = true);

    // TODO: POST /api/mail-accounts/{accountId}/send via Dio
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mail sent'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}

class _PickedFile {
  final String path;
  const _PickedFile({required this.path});
}