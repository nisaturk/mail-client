import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/api_client.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool registeredPending;
  final bool isLoggedIn;
  final String? userId;
  final String? email;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.registeredPending = false,
    this.isLoggedIn = false,
    this.userId,
    this.email,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? registeredPending,
    bool? isLoggedIn,
    String? userId,
    String? email,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      registeredPending: registeredPending ?? this.registeredPending,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      email: email ?? this.email,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final TokenStorage _tokenStorage;

  AuthNotifier(this._api, this._tokenStorage) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['accessToken'] as String?;
      if (token == null) throw Exception('No token in response');
      final userId = data['userId'] as String? ?? '';
      final userEmail = data['email'] as String? ?? email;

      await _tokenStorage.write(token);
      await _tokenStorage.writeUserId(userId);
      await _tokenStorage.writeEmail(userEmail);

      state = AuthState(
        isLoggedIn: true,
        userId: userId,
        email: userEmail,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String msg;
      if (statusCode == 403) {
        msg = 'Your account is waiting for approval.';
      } else {
        final data = e.response?.data;
        final message = data is Map ? data['message'] : null;
        msg = (message ?? e.message)?.toString() ?? 'Login failed';
      }
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(String email, String password, {String displayName = ''}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _api.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      state = const AuthState(registeredPending: true);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.message)?.toString()
          : e.message?.toString() ?? 'Registration failed';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void logout() {
    _tokenStorage.clearAll();
    state = const AuthState();
  }

  Future<void> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null) return;
    final userId = await _tokenStorage.readUserId();
    final email = await _tokenStorage.readEmail();
    state = AuthState(
      isLoggedIn: true,
      userId: userId,
      email: email,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(api, tokenStorage);
});

final emailControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final passwordControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Email is required';
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}
