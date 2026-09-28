import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'api_client.dart';

class AdminRepository {
  final ApiClient _api;

  AdminRepository(this._api);

  Future<List<User>> getUsers() async {
    try {
      final response = await _api.dio.get('/admin/users');
      final list = response.data as List<dynamic>;
      return list
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to load users');
    }
  }

  Future<User> createUser(String email, String displayName) async {
    try {
      final response = await _api.dio.post(
        '/admin/users',
        data: {'email': email, 'displayName': displayName},
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to create user');
    }
  }

  Future<void> approveUser(String id) async {
    try {
      await _api.dio.patch('/admin/users/$id/approve');
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to approve user');
    }
  }

  Future<void> disableUser(String id) async {
    try {
      await _api.dio.patch('/admin/users/$id/disable');
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to disable user');
    }
  }

  Future<void> enableUser(String id) async {
    try {
      await _api.dio.patch('/admin/users/$id/enable');
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to enable user');
    }
  }

  Future<void> resetPassword(String id) async {
    try {
      await _api.dio.post('/admin/users/$id/reset-password');
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to reset password');
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AdminRepository(api);
});
