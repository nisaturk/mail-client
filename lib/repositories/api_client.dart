import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

const _tokenKey = 'jwt_token';

class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> delete() => _storage.delete(key: _tokenKey);
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _tokenStorage.delete();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushReplacementNamed('/');
      });
    }
    handler.next(err);
  }
}

const defaultBaseUrl = 'http://10.0.2.2:5000/api';

class ApiClient {
  late final Dio dio;

  ApiClient({
    String? baseUrl,
    TokenStorage? tokenStorage,
  }) {
    final storage = tokenStorage ?? TokenStorage();
    final interceptor = AuthInterceptor(storage);

    dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? defaultBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(interceptor);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: storage);
});
