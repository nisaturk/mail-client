import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_account.dart';
import '../models/enums.dart';

final _mockAccounts = [
  MailAccount(
    id: '1',
    emailAddress: 'ahmet@tekyazilim.com',
    displayName: 'Ahmet',
    username: 'ahmet',
    imapHost: 'imap.tekyazilim.com',
    imapPort: 993,
    imapSecurity: MailSecurity.sslOnConnect,
    smtpHost: 'smtp.tekyazilim.com',
    smtpPort: 587,
    smtpSecurity: MailSecurity.startTls,
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 6, 1),
  ),
  MailAccount(
    id: '2',
    emailAddress: 'destek@tekyazilim.com',
    displayName: 'Destek',
    username: 'destek',
    imapHost: 'imap.tekyazilim.com',
    imapPort: 993,
    imapSecurity: MailSecurity.sslOnConnect,
    smtpHost: 'smtp.tekyazilim.com',
    smtpPort: 587,
    smtpSecurity: MailSecurity.startTls,
    isActive: true,
    createdAt: DateTime(2025, 3, 15),
    updatedAt: DateTime(2025, 7, 20),
  ),
];

class MailAccountsState {
  final List<MailAccount> accounts;
  final bool isLoading;
  final String? error;

  const MailAccountsState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
  });

  MailAccountsState copyWith({
    List<MailAccount>? accounts,
    bool? isLoading,
    String? error,
  }) {
    return MailAccountsState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MailAccountsNotifier extends StateNotifier<MailAccountsState> {
  final bool _useMock;

  MailAccountsNotifier({
    this._useMock = true,
  }) : super(const MailAccountsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      state = MailAccountsState(accounts: _mockAccounts.toList());
    }
  }

  Future<void> add(MailAccount account) async {
    state = state.copyWith(isLoading: true);
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final now = DateTime.now();
      final newAccount = account.copyWith(
        id: now.millisecondsSinceEpoch.toString(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      state = state.copyWith(
        accounts: [...state.accounts, newAccount],
        isLoading: false,
      );
    }
  }

  Future<void> update(MailAccount account) async {
    state = state.copyWith(isLoading: true);
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final updated = state.accounts.map((a) {
        return a.id == account.id
            ? account.copyWith(
                id: a.id,
                isActive: a.isActive,
                createdAt: a.createdAt,
              )
            : a;
      }).toList();
      state = state.copyWith(accounts: updated, isLoading: false);
    }
  }

  Future<void> delete(String id) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      state = state.copyWith(
        accounts: state.accounts.where((a) => a.id != id).toList(),
      );
    }
  }

  Future<bool> testConnection(String id) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    return false;
  }
}

final mailAccountsProvider =
    StateNotifierProvider<MailAccountsNotifier, MailAccountsState>((ref) {
  return MailAccountsNotifier()..load();
});
