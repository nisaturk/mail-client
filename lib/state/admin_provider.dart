import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/enums.dart';

final _mockUsers = [
  User(
    id: '1',
    email: 'admin@flapmail.com',
    displayName: 'Admin',
    role: UserRole.admin,
    status: UserStatus.active,
    createdAt: DateTime(2024, 1, 1),
    lastLoginAt: DateTime(2025, 9, 1),
  ),
  User(
    id: '2',
    email: 'ahmet@tekyazilim.com',
    displayName: 'Ahmet',
    role: UserRole.user,
    status: UserStatus.active,
    createdAt: DateTime(2025, 1, 15),
    lastLoginAt: DateTime(2025, 8, 20),
  ),
  User(
    id: '3',
    email: 'mehmet@example.com',
    displayName: 'Mehmet',
    role: UserRole.user,
    status: UserStatus.pending,
    createdAt: DateTime(2025, 9, 1),
  ),
  User(
    id: '4',
    email: 'zeynep@example.com',
    displayName: 'Zeynep',
    role: UserRole.user,
    status: UserStatus.disabled,
    createdAt: DateTime(2025, 3, 10),
    lastLoginAt: DateTime(2025, 6, 5),
  ),
];

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

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(const AdminState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = AdminState(users: _mockUsers.toList());
  }

  Future<void> approve(String userId) =>
      _setStatus(userId, UserStatus.active);

  Future<void> disable(String userId) =>
      _setStatus(userId, UserStatus.disabled);

  Future<void> enable(String userId) =>
      _setStatus(userId, UserStatus.active);

  Future<void> createUser(String email, String displayName) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      displayName: displayName,
      role: UserRole.user,
      status: UserStatus.pending,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      users: [...state.users, newUser],
      isLoading: false,
    );
  }

  Future<void> resetPassword(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // In real app: POST /api/admin/users/{id}/reset-password
  }

  Future<void> _setStatus(String userId, UserStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _updateUser(userId, (u) => u.copyWith(status: status));
  }

  void _updateUser(String id, User Function(User) transform) {
    state = state.copyWith(
      users: state.users.map((u) => u.id == id ? transform(u) : u).toList(),
    );
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier()..load();
});
