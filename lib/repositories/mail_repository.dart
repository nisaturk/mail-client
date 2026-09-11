import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SendResult {
  final bool sent;
  final bool? sentCopySaved;
  final String? warning;
  final bool deliveryUncertain;
  final String? error;
  final bool retryable;

  const SendResult({
    this.sent = false,
    this.sentCopySaved,
    this.warning,
    this.deliveryUncertain = false,
    this.error,
    this.retryable = false,
  });
}

/// Sends a mail with an [idempotencyKey] (v4 UUID) tied to this logical send.
/// Reuse the exact same key when retrying the same send; a brand new send
/// action gets a brand new key.
Future<SendResult> sendMail({
  required Dio dio,
  required String accountId,
  required String toAddress,
  required String subject,
  String? bodyHtml,
  String? bodyText,
  List<MultipartFile> attachments = const [],
  required String idempotencyKey,
}) async {
  final formData = FormData.fromMap({
    'toAddress': toAddress,
    'subject': subject,
    if (bodyHtml != null && bodyHtml.isNotEmpty) 'bodyHtml': bodyHtml,
    if (bodyText != null && bodyText.isNotEmpty) 'bodyText': bodyText,
    ...{for (final f in attachments) f.filename ?? 'attachment': f},
  });
  try {
    final response = await dio.post(
      '/mail-accounts/$accountId/send',
      data: formData,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    final data = (response.data ?? const {}) as Map<String, dynamic>;
    return SendResult(
      sent: data['sent'] as bool? ?? true,
      sentCopySaved: data['sentCopySaved'] as bool? ?? true,
      warning: data['warning'] as String?,
    );
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    if (status == 409) {
      return const SendResult(
        deliveryUncertain: true,
        error:
            'Delivery may have already occurred — check your mailbox before sending again.',
      );
    }
    if (status == 502 || status == null) {
      return SendResult(
        retryable: true,
        error: status == 502
            ? 'The mail server failed. Try sending again.'
            : 'Could not reach the server. Check your connection and try again.',
      );
    }
    final message = e.response?.data is Map
        ? (e.response?.data['message'] ?? e.message)?.toString()
        : e.message?.toString();
    return SendResult(error: message ?? 'Failed to send mail');
  }
}

/// Downloads an attachment's bytes to the app temp dir.
/// Returns the local file path, or `null` when the attachment is gone (404).
Future<String?> downloadAttachment({
  required Dio dio,
  required String mailId,
  required String attachmentId,
  required String fileName,
}) async {
  try {
    final response = await dio.get(
      '/mails/$mailId/attachments/$attachmentId',
      options: Options(responseType: ResponseType.bytes),
    );
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(response.data as List<int>);
    return file.path;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
}