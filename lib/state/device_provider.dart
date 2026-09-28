import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/device_repository.dart';

class DeviceState {
  final String? deviceId;
  final bool isRegistered;
  final String? error;

  const DeviceState({
    this.deviceId,
    this.isRegistered = false,
    this.error,
  });

  DeviceState copyWith({
    String? deviceId,
    bool? isRegistered,
    String? error,
  }) {
    return DeviceState(
      deviceId: deviceId ?? this.deviceId,
      isRegistered: isRegistered ?? this.isRegistered,
      error: error,
    );
  }
}

class DeviceNotifier extends Notifier<DeviceState> {
  @override
  DeviceState build() {
    return const DeviceState();
  }

  DeviceRepository get _repo => ref.read(deviceRepositoryProvider);

  Future<void> registerDevice({
    required String pushToken,
    required String platform,
  }) async {
    try {
      final reg = await _repo.registerDevice(
        pushToken: pushToken,
        platform: platform,
      );
      state = DeviceState(
        deviceId: reg.id,
        isRegistered: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> unregisterDevice() async {
    if (state.deviceId != null) {
      try {
        await _repo.deleteDevice(state.deviceId!);
      } catch (_) {}
    }
    state = const DeviceState();
  }
}

final deviceProvider = NotifierProvider<DeviceNotifier, DeviceState>(
  DeviceNotifier.new,
);
