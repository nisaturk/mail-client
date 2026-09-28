import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/enums.dart';
import '../repositories/admin_repository.dart';

class AdminState {
  final List<User> users;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends Notifier<AdminState> {
  @override
  AdminState build() {
    Future.microtask(() => load());
    return const AdminState();
  }

  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repo.getUsers();
      state = AdminState(users: users);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> approve(String userId) =>
      _setStatus(userId, UserStatus.active);

  Future<void> disable(String userId) =>
      _setStatus(userId, UserStatus.disabled);

  Future<void> enable(String userId) =>
      _setStatus(userId, UserStatus.active);

  Future<void> createUser(String email, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _repo.createUser(email, displayName);
      state = state.copyWith(
        users: [...state.users, created],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> resetPassword(String userId) async {
    try {
      await _repo.resetPassword(userId);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _setStatus(String userId, UserStatus status) async {
    try {
      if (status == UserStatus.active) {
        await _repo.approveUser(userId);
      } else if (status == UserStatus.disabled) {
        await _repo.disableUser(userId);
      }
      _updateUser(userId, (u) => u.copyWith(status: status));
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _updateUser(String id, User Function(User) transform) {
    state = state.copyWith(
      users: state.users.map((u) => u.id == id ? transform(u) : u).toList(),
    );
  }
}

final adminProvider = NotifierProvider<AdminNotifier, AdminState>(AdminNotifier.new);
