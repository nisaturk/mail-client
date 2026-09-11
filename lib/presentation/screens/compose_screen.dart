import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../models/mail_account.dart';
import '../../state/mail_accounts_provider.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  final String? initialTo;
  final String? initialSubject;
  final String? initialBody;

  const ComposeScreen({
    super.key,
    this.initialTo,
    this.initialSubject,
    this.initialBody,
  });

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

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(mailAccountsProvider);
    final activeAccounts =
        accountsState.accounts.where((a) => a.isActive).toList();

    if (_selectedAccount == null && activeAccounts.isNotEmpty) {
      _selectedAccount = activeAccounts.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose'),
        actions: [
          IconButton(
            onPressed: _sending ? null : _pickAttachment,
            icon: const Icon(Icons.attach_file),
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
                initialValue: _selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                items: activeAccounts
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.emailAddress),
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
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _attachments.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final f = _attachments[index];
                    return Chip(
                      avatar: const Icon(Icons.description, size: 18),
                      label: Text(
                        p.basename(f.path),
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () =>
                          setState(() => _attachments.removeAt(index)),
                    );
                  },
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Sending...' : 'Send'),
            ),
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
