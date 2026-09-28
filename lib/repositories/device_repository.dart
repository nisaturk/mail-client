import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

class DeviceRegistration {
  final String id;
  final String platform;
  final DateTime? registeredAt;
  final DateTime? lastSeenAt;

  const DeviceRegistration({
    required this.id,
    required this.platform,
    this.registeredAt,
    this.lastSeenAt,
  });

  factory DeviceRegistration.fromJson(Map<String, dynamic> json) {
    return DeviceRegistration(
      id: json['id'] as String? ?? '',
      platform: json['platform'] as String? ?? 'android',
      registeredAt: json['registeredAt'] != null
          ? DateTime.parse(json['registeredAt'] as String)
          : null,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'] as String)
          : null,
    );
  }
}

class DeviceRepository {
  final ApiClient _api;

  DeviceRepository(this._api);

  Future<DeviceRegistration> registerDevice({
    required String pushToken,
    required String platform,
  }) async {
    try {
      final response = await _api.dio.post(
        '/devices/register',
        data: {
          'pushToken': pushToken,
          'platform': platform.toLowerCase(),
        },
      );
      return DeviceRegistration.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to register device');
    }
  }

  Future<void> deleteDevice(String id) async {
    try {
      await _api.dio.delete('/devices/$id');
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to delete device registration');
    }
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return DeviceRepository(api);
});
