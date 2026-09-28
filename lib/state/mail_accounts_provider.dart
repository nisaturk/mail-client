import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_account.dart';
import '../repositories/mail_account_repository.dart';

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

class MailAccountsNotifier extends Notifier<MailAccountsState> {
  @override
  MailAccountsState build() {
    Future.microtask(() => load());
    return const MailAccountsState();
  }

  MailAccountRepository get _repo => ref.read(mailAccountRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final accounts = await _repo.getAccounts();
      state = MailAccountsState(accounts: accounts);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> add(MailAccount account, {String password = ''}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _repo.createAccount(account, password: password);
      state = state.copyWith(
        accounts: [...state.accounts, created],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> update(MailAccount account, {String? password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repo.updateAccount(account, password: password);
      final list = state.accounts
          .map((a) => a.id == updated.id ? updated : a)
          .toList();
      state = state.copyWith(accounts: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.deleteAccount(id);
      state = state.copyWith(
        accounts: state.accounts.where((a) => a.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> testConnection(String id) async {
    final res = await _repo.testConnection(id);
    return res.succeeded;
  }
}

final mailAccountsProvider =
    NotifierProvider<MailAccountsNotifier, MailAccountsState>(
  MailAccountsNotifier.new,
);
