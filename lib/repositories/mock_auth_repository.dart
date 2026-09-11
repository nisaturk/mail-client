import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockAuthRepository {
  Future<String> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'mock.jwt.token';
  }

  Future<void> register(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}

final mockAuthRepositoryProvider = Provider<MockAuthRepository>((ref) {
  return MockAuthRepository();
});
