import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_account.dart';
import '../models/enums.dart';
import 'api_client.dart';

class MailFolderInfo {
  final String id;
  final String name;
  final String fullName;
  final MailFolderType folderType;
  final int? uidValidity;
  final bool isSyncEnabled;
  final bool isAvailable;

  const MailFolderInfo({
    required this.id,
    required this.name,
    required this.fullName,
    required this.folderType,
    this.uidValidity,
    required this.isSyncEnabled,
    required this.isAvailable,
  });

  factory MailFolderInfo.fromJson(Map<String, dynamic> json) {
    return MailFolderInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      folderType: MailFolderType.fromJson(json['folderType'] as String?),
      uidValidity: json['uidValidity'] as int?,
      isSyncEnabled: json['isSyncEnabled'] as bool? ?? true,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}

class TestConnectionResult {
  final bool succeeded;
  final String message;
  final List<MailFolderInfo>? folders;

  const TestConnectionResult({
    required this.succeeded,
    required this.message,
    this.folders,
  });

  factory TestConnectionResult.fromJson(Map<String, dynamic> json) {
    return TestConnectionResult(
      succeeded: json['succeeded'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      folders: (json['folders'] as List<dynamic>?)
          ?.map((f) => MailFolderInfo.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MailAccountRepository {
  final ApiClient _api;

  MailAccountRepository(this._api);

  Future<List<MailAccount>> getAccounts() async {
    try {
      final response = await _api.dio.get('/mail-accounts');
      final list = response.data as List<dynamic>;
      return list
          .map((item) => MailAccount.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to load mail accounts');
    }
  }

  Future<MailAccount> getAccount(String id) async {
    try {
      final response = await _api.dio.get('/mail-accounts/$id');
      return MailAccount.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to load account');
    }
  }

  Future<MailAccount> createAccount(MailAccount account, {required String password}) async {
    try {
      final body = account.toJson(password: password);
      final response = await _api.dio.post('/mail-accounts', data: body);
      return MailAccount.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Account with this email address already exists');
      }
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to create account');
    }
  }

  Future<MailAccount> updateAccount(MailAccount account, {String? password}) async {
    try {
      final body = account.toJson(password: password);
      final response = await _api.dio.put('/mail-accounts/${account.id}', data: body);
      return MailAccount.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to update account');
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await _api.dio.delete('/mail-accounts/$id');
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to delete account');
    }
  }

  Future<TestConnectionResult> testConnection(String id) async {
    try {
      final response = await _api.dio.post('/mail-accounts/$id/test');
      return TestConnectionResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      return TestConnectionResult(succeeded: false, message: msg?.toString() ?? 'Test failed');
    }
  }

  Future<List<MailFolderInfo>> getFolders(String accountId) async {
    try {
      final response = await _api.dio.get('/mail-accounts/$accountId/folders');
      final list = response.data as List<dynamic>;
      return list
          .map((item) => MailFolderInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to load folders');
    }
  }
}

final mailAccountRepositoryProvider = Provider<MailAccountRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MailAccountRepository(api);
});
