import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

class AuthResponse {
  final String accessToken;
  final String userId;
  final String email;
  final String role;

  const AuthResponse({
    required this.accessToken,
    required this.userId,
    required this.email,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? json['token'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'User',
    );
  }
}

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _api.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Account is pending admin approval');
      }
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Login failed');
    }
  }

  Future<String> register(String email, String password, String displayName) async {
    try {
      final response = await _api.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      final msg = response.data['message'] as String? ??
          'Registration request submitted successfully.';
      return msg;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Registration failed');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthRepository(api);
});
