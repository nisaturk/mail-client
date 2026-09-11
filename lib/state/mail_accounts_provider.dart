import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_account.dart';
import '../models/enums.dart';
import '../repositories/api_client.dart';
import '../repositories/api_config.dart';

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
  final Dio _dio;

  MailAccountsNotifier({Dio? dio})
      : _dio = dio!,
        super(const MailAccountsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    if (useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      state = MailAccountsState(accounts: _mockAccounts.toList());
      return;
    }
    try {
      final response = await _dio.get('/mail-accounts');
      final items = (response.data as List<dynamic>)
          .map((e) => MailAccount.fromJson(e as Map<String, dynamic>))
          .toList();
      state = MailAccountsState(accounts: items);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> add(MailAccount account) async {
    state = state.copyWith(isLoading: true);
    if (useMockApi) {
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
      return;
    }
    try {
      final response = await _dio.post(
        '/mail-accounts',
        data: account.toJson(),
      );
      final created =
          MailAccount.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(
        accounts: [...state.accounts, created],
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> update(MailAccount account) async {
    state = state.copyWith(isLoading: true);
    if (useMockApi) {
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
      return;
    }
    try {
      await _dio.put('/mail-accounts/${account.id}', data: account.toJson());
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
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> delete(String id) async {
    if (useMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      state = state.copyWith(
        accounts: state.accounts.where((a) => a.id != id).toList(),
      );
      return;
    }
    try {
      await _dio.delete('/mail-accounts/$id');
      state = state.copyWith(
        accounts: state.accounts.where((a) => a.id != id).toList(),
      );
    } on DioException catch (e) {
      state = state.copyWith(error: _errorMessage(e));
    }
  }

  Future<bool> testConnection(String id) async {
    if (useMockApi) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    try {
      await _dio.post('/mail-accounts/$id/test');
      return true;
    } on DioException {
      return false;
    }
  }

  String _errorMessage(DioException e) =>
      e.response?.data is Map
          ? (e.response?.data['message'] ?? e.message)?.toString() ??
              'Failed to load mail accounts'
          : e.message ?? 'Failed to load mail accounts';
}

final mailAccountsProvider =
    StateNotifierProvider<MailAccountsNotifier, MailAccountsState>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return MailAccountsNotifier(dio: dio)..load();
});