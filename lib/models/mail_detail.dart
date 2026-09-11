import 'attachment.dart';
import 'enums.dart';

class MailDetail {
  final String id;
  final String mailAccountId;
  final String mailAccountEmail;
  final MailFolderType folderType;
  final String fromDisplayName;
  final String fromAddress;
  final String toAddress;
  final String subject;
  final DateTime? receivedAt;
  final bool isRead;
  final bool hasAttachments;
  final String bodyHtml;
  final String bodyText;
  final List<Attachment> attachments;

  const MailDetail({
    required this.id,
    required this.mailAccountId,
    required this.mailAccountEmail,
    required this.folderType,
    required this.fromDisplayName,
    required this.fromAddress,
    required this.toAddress,
    required this.subject,
    this.receivedAt,
    required this.isRead,
    required this.hasAttachments,
    this.bodyHtml = '',
    this.bodyText = '',
    this.attachments = const [],
  });

  factory MailDetail.fromJson(Map<String, dynamic> json) {
    return MailDetail(
      id: json['id'] as String,
      mailAccountId: json['mailAccountId'] as String,
      mailAccountEmail: json['mailAccountEmail'] as String? ?? '',
      folderType: MailFolderType.values.firstWhere(
        (e) => e.name == json['folderType'],
        orElse: () => MailFolderType.unknown,
      ),
      fromDisplayName: json['fromDisplayName'] as String? ?? '',
      fromAddress: json['fromAddress'] as String? ?? '',
      toAddress: json['toAddress'] as String? ?? '',
      subject: json['subject'] as String? ?? '(no subject)',
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      hasAttachments: json['hasAttachments'] as bool? ?? false,
      bodyHtml: json['bodyHtml'] as String? ?? '',
      bodyText: json['bodyText'] as String? ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((a) => Attachment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
