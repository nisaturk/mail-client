import 'enums.dart';

class MailSummary {
  final String id;
  final String mailAccountId;
  final String mailAccountEmail;
  final MailFolderType folderType;
  final String fromDisplayName;
  final String fromAddress;
  final String subject;
  final String preview;
  final DateTime receivedAt;
  final bool isRead;
  final bool hasAttachments;

  const MailSummary({
    required this.id,
    required this.mailAccountId,
    required this.mailAccountEmail,
    required this.folderType,
    required this.fromDisplayName,
    required this.fromAddress,
    required this.subject,
    this.preview = '',
    required this.receivedAt,
    required this.isRead,
    required this.hasAttachments,
  });

  factory MailSummary.fromJson(Map<String, dynamic> json) {
    return MailSummary(
      id: json['id'] as String,
      mailAccountId: json['mailAccountId'] as String,
      mailAccountEmail: json['mailAccountEmail'] as String? ?? '',
      folderType: MailFolderType.values.firstWhere(
        (e) => e.name == json['folderType'],
        orElse: () => MailFolderType.unknown,
      ),
      fromDisplayName: json['fromDisplayName'] as String? ?? '',
      fromAddress: json['fromAddress'] as String? ?? '',
      subject: json['subject'] as String? ?? '(no subject)',
      preview: json['preview'] ?? json['snippet'] ?? '',
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      hasAttachments: json['hasAttachments'] as bool? ?? false,
    );
  }

  MailSummary copyWith({
    String? mailAccountId,
    String? mailAccountEmail,
    MailFolderType? folderType,
    String? fromDisplayName,
    String? fromAddress,
    String? subject,
    String? preview,
    DateTime? receivedAt,
    bool? isRead,
    bool? hasAttachments,
  }) {
    return MailSummary(
      id: id,
      mailAccountId: mailAccountId ?? this.mailAccountId,
      mailAccountEmail: mailAccountEmail ?? this.mailAccountEmail,
      folderType: folderType ?? this.folderType,
      fromDisplayName: fromDisplayName ?? this.fromDisplayName,
      fromAddress: fromAddress ?? this.fromAddress,
      subject: subject ?? this.subject,
      preview: preview ?? this.preview,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      hasAttachments: hasAttachments ?? this.hasAttachments,
    );
  }
}
