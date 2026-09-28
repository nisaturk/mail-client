import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_summary.dart';
import '../models/mail_detail.dart';
import '../models/enums.dart';
import 'api_client.dart';

class SendMailResult {
  final bool sent;
  final bool sentCopySaved;
  final String? warning;

  const SendMailResult({
    required this.sent,
    required this.sentCopySaved,
    this.warning,
  });

  factory SendMailResult.fromJson(Map<String, dynamic> json) {
    return SendMailResult(
      sent: json['sent'] as bool? ?? true,
      sentCopySaved: json['sentCopySaved'] as bool? ?? true,
      warning: json['warning'] as String?,
    );
  }
}

class MailRepository {
  final ApiClient _api;

  MailRepository(this._api);

  Future<MailPagedResult> getMails({
    String? accountId,
    MailFolderType? folderType,
    String? folderId,
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (accountId != null && accountId.isNotEmpty) {
        query['accountId'] = accountId;
      }
      if (folderType != null) {
        query['folderType'] = folderType.toJson();
      }
      if (folderId != null && folderId.isNotEmpty) {
        query['folderId'] = folderId;
      }

      final response = await _api.dio.get('/mails', queryParameters: query);
      return MailPagedResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to load mails');
    }
  }

  Future<MailDetail> getMailDetail(String id) async {
    try {
      final response = await _api.dio.get('/mails/$id');
      return MailDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to load mail detail');
    }
  }

  Future<bool> markAsRead(String id, bool isRead) async {
    try {
      final response = await _api.dio.patch(
        '/mails/$id/read',
        data: {'isRead': isRead},
      );
      return response.data['isRead'] as bool? ?? isRead;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Mail folder changed on server; please refresh.');
      }
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to update read status');
    }
  }

  Future<SendMailResult> sendMail({
    required String accountId,
    required String toAddress,
    required String subject,
    String? bodyHtml,
    String? bodyText,
    List<String> attachmentPaths = const [],
    required String idempotencyKey,
  }) async {
    try {
      final formData = FormData.fromMap({
        'toAddress': toAddress,
        'subject': subject,
        if (bodyHtml != null && bodyHtml.isNotEmpty) 'bodyHtml': bodyHtml,
        if (bodyText != null && bodyText.isNotEmpty) 'bodyText': bodyText,
      });

      for (final path in attachmentPaths) {
        formData.files.add(MapEntry(
          'attachments',
          await MultipartFile.fromFile(path),
        ));
      }

      final response = await _api.dio.post(
        '/mail-accounts/$accountId/send',
        data: formData,
        options: Options(
          headers: {
            'Idempotency-Key': idempotencyKey,
          },
        ),
      );

      return SendMailResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception(
            'Message status uncertain or key conflict. Please check your sent folder before retrying.');
      }
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to send mail');
    }
  }
}

final mailRepositoryProvider = Provider<MailRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MailRepository(api);
});
