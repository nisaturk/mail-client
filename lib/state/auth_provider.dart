import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/api_client.dart';
import '../repositories/auth_repository.dart';

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

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  AuthRepository get _authRepo => ref.read(authRepositoryProvider);
  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authRes = await _authRepo.login(email, password);
      await _tokenStorage.write(authRes.accessToken);
      final isAdmin = authRes.role.toLowerCase() == 'admin';
      state = AuthState(isLoggedIn: true, isAdmin: isAdmin);
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(String email, String password, {required String displayName}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepo.register(email, password, displayName);
      state = const AuthState(registeredPending: true);
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: msg);
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

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

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

final displayNameControllerProvider = Provider<TextEditingController>((ref) {
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

String? validateDisplayName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Display name is required';
  return null;
}
