import 'enums.dart';

class MailAccount {
  final String id;
  final String emailAddress;
  final String displayName;
  final String username;

  final String imapHost;
  final int imapPort;
  final MailSecurity imapSecurity;

  final String smtpHost;
  final int smtpPort;
  final MailSecurity smtpSecurity;

  final bool saveSentCopy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MailAccount({
    required this.id,
    required this.emailAddress,
    required this.displayName,
    required this.username,
    required this.imapHost,
    required this.imapPort,
    required this.imapSecurity,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpSecurity,
    this.saveSentCopy = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MailAccount.fromJson(Map<String, dynamic> json) {
    return MailAccount(
      id: json['id'] as String,
      emailAddress: json['emailAddress'] as String,
      displayName: json['displayName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      imapHost: json['imapHost'] as String,
      imapPort: json['imapPort'] as int,
      imapSecurity: MailSecurity.values.firstWhere(
        (e) => e.name == json['imapSecurity'],
        orElse: () => MailSecurity.sslOnConnect,
      ),
      smtpHost: json['smtpHost'] as String,
      smtpPort: json['smtpPort'] as int,
      smtpSecurity: MailSecurity.values.firstWhere(
        (e) => e.name == json['smtpSecurity'],
        orElse: () => MailSecurity.sslOnConnect,
      ),
      saveSentCopy: json['saveSentCopy'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'emailAddress': emailAddress,
        'displayName': displayName,
        'username': username,
        'password': '',
        'imapHost': imapHost,
        'imapPort': imapPort,
        'imapSecurity': imapSecurity.name,
        'smtpHost': smtpHost,
        'smtpPort': smtpPort,
        'smtpSecurity': smtpSecurity.name,
        'saveSentCopy': saveSentCopy,
      };

  MailAccount copyWith({
    String? id,
    String? emailAddress,
    String? displayName,
    String? username,
    String? imapHost,
    int? imapPort,
    MailSecurity? imapSecurity,
    String? smtpHost,
    int? smtpPort,
    MailSecurity? smtpSecurity,
    bool? saveSentCopy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MailAccount(
      id: id ?? this.id,
      emailAddress: emailAddress ?? this.emailAddress,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      imapSecurity: imapSecurity ?? this.imapSecurity,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpSecurity: smtpSecurity ?? this.smtpSecurity,
      saveSentCopy: saveSentCopy ?? this.saveSentCopy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
