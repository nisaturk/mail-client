import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mail_account.dart';
import '../../models/enums.dart';
import '../../state/mail_accounts_provider.dart';

class AddEditMailAccountScreen extends ConsumerStatefulWidget {
  final MailAccount? account;
  const AddEditMailAccountScreen({super.key, this.account});

  @override
  ConsumerState<AddEditMailAccountScreen> createState() =>
      _AddEditMailAccountScreenState();
}

class _AddEditMailAccountScreenState
    extends ConsumerState<AddEditMailAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _imapHostCtrl;
  late final TextEditingController _imapPortCtrl;
  late final TextEditingController _smtpHostCtrl;
  late final TextEditingController _smtpPortCtrl;
  late MailSecurity _imapSecurity;
  late MailSecurity _smtpSecurity;
  late bool _saveSentCopy;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _emailCtrl = TextEditingController(text: a?.emailAddress ?? '');
    _displayNameCtrl = TextEditingController(text: a?.displayName ?? '');
    _usernameCtrl = TextEditingController(text: a?.username ?? '');
    _passwordCtrl = TextEditingController();
    _imapHostCtrl = TextEditingController(text: a?.imapHost ?? '');
    _imapPortCtrl = TextEditingController(text: '${a?.imapPort ?? 993}');
    _smtpHostCtrl = TextEditingController(text: a?.smtpHost ?? '');
    _smtpPortCtrl = TextEditingController(text: '${a?.smtpPort ?? 587}');
    _imapSecurity = a?.imapSecurity ?? MailSecurity.sslOnConnect;
    _smtpSecurity = a?.smtpSecurity ?? MailSecurity.startTls;
    _saveSentCopy = a?.saveSentCopy ?? true;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _imapHostCtrl.dispose();
    _imapPortCtrl.dispose();
    _smtpHostCtrl.dispose();
    _smtpPortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Account' : 'Add Account'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _displayNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Password (leave blank to keep)' : 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outlined),
              ),
              obscureText: true,
              validator: (v) {
                if (!_isEditing && (v == null || v.isEmpty)) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'IMAP',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imapHostCtrl,
              decoration: const InputDecoration(
                labelText: 'IMAP Host',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _imapPortCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<MailSecurity>(
                    initialValue: _imapSecurity,
                    decoration: const InputDecoration(
                      labelText: 'Security',
                      border: OutlineInputBorder(),
                    ),
                    items: MailSecurity.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(_securityLabel(s)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _imapSecurity = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'SMTP',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _smtpHostCtrl,
              decoration: const InputDecoration(
                labelText: 'SMTP Host',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _smtpPortCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<MailSecurity>(
                    initialValue: _smtpSecurity,
                    decoration: const InputDecoration(
                      labelText: 'Security',
                      border: OutlineInputBorder(),
                    ),
                    items: MailSecurity.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(_securityLabel(s)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _smtpSecurity = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Save sent copy'),
              subtitle: const Text('Append sent mail to Sent folder via IMAP'),
              value: _saveSentCopy,
              onChanged: (v) => setState(() => _saveSentCopy = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Save Changes' : 'Add Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final account = MailAccount(
      id: widget.account?.id ?? '',
      emailAddress: _emailCtrl.text.trim(),
      displayName: _displayNameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      imapHost: _imapHostCtrl.text.trim(),
      imapPort: int.tryParse(_imapPortCtrl.text.trim()) ?? 993,
      imapSecurity: _imapSecurity,
      smtpHost: _smtpHostCtrl.text.trim(),
      smtpPort: int.tryParse(_smtpPortCtrl.text.trim()) ?? 587,
      smtpSecurity: _smtpSecurity,
      saveSentCopy: _saveSentCopy,
      createdAt: widget.account?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(mailAccountsProvider.notifier);
    final future = _isEditing ? notifier.update(account) : notifier.add(account);
    future.then((_) {
      if (mounted) Navigator.pop(context, true);
    });
  }

  String _securityLabel(MailSecurity s) {
    switch (s) {
      case MailSecurity.none:
        return 'None';
      case MailSecurity.sslOnConnect:
        return 'SSL/TLS';
      case MailSecurity.startTls:
        return 'STARTTLS';
    }
  }
}
