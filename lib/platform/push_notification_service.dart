import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../presentation/screens/mail_detail_screen.dart';
import '../state/device_provider.dart';

class PushNotificationService {
  final WidgetRef _ref;

  PushNotificationService(this._ref);

  String get platformName => Platform.isIOS ? 'ios' : 'android';

  Future<void> onTokenReceived(String token) async {
    await _ref.read(deviceProvider.notifier).registerDevice(
          pushToken: token,
          platform: platformName,
        );
  }

  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final mailId = data['mailId'] as String?;

    if (type == 'new_mail' && mailId != null && mailId.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => MailDetailScreen(mailId: mailId),
        ),
      );
    }
  }
}
