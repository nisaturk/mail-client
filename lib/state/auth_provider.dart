import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/api_client.dart';
import '../repositories/mock_auth_repository.dart';

const useMockApi = true;

class AuthState {
  final bool isLoading;
  final String? error;
  final bool registeredPending;
  final bool isLoggedIn;
  final bool isAdmin;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.registeredPending = false,
    this.isLoggedIn = false,
    this.isAdmin = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? registeredPending,
    bool? isLoggedIn,
    bool? isAdmin,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      registeredPending: registeredPending ?? this.registeredPending,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final MockAuthRepository _mock;
  final TokenStorage _tokenStorage;

  AuthNotifier(this._api, this._mock, this._tokenStorage)
      : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      if (useMockApi) {
        await _mock.login(email, password);
        await _tokenStorage.write('mock.jwt.token');
        state = const AuthState(isLoggedIn: true, isAdmin: true);
      } else {
        final response = await _api.dio.post(
          '/auth/login',
          data: {'email': email, 'password': password},
        );
        final token = response.data['token'] as String?;
        if (token == null) throw Exception('No token in response');
        await _tokenStorage.write(token);
        final role = response.data['role'] as String? ?? 'User';
        state = AuthState(isLoggedIn: true, isAdmin: role == 'Admin');
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      state = state.copyWith(isLoading: false, error: msg?.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      if (useMockApi) {
        await _mock.register(email, password);
      } else {
        await _api.dio.post(
          '/auth/register',
          data: {'email': email, 'password': password},
        );
      }
      state = const AuthState(registeredPending: true);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      state = state.copyWith(isLoading: false, error: msg?.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void logout() {
    _tokenStorage.delete();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  final mock = ref.watch(mockAuthRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(api, mock, tokenStorage);
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
