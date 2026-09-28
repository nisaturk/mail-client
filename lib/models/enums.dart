enum UserRole {
  user,
  admin;

  String toJson() => switch (this) {
        UserRole.user => 'User',
        UserRole.admin => 'Admin',
      };

  static UserRole fromJson(String? value) {
    if (value == null) return UserRole.user;
    switch (value.trim().toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

enum UserStatus {
  pending,
  active,
  disabled;

  String toJson() => switch (this) {
        UserStatus.pending => 'Pending',
        UserStatus.active => 'Active',
        UserStatus.disabled => 'Disabled',
      };

  static UserStatus fromJson(String? value) {
    if (value == null) return UserStatus.pending;
    switch (value.trim().toLowerCase()) {
      case 'active':
        return UserStatus.active;
      case 'disabled':
        return UserStatus.disabled;
      case 'pending':
      default:
        return UserStatus.pending;
    }
  }
}

enum MailSecurity {
  none,
  sslOnConnect,
  startTls;

  String toJson() => switch (this) {
        MailSecurity.none => 'None',
        MailSecurity.sslOnConnect => 'SslOnConnect',
        MailSecurity.startTls => 'StartTls',
      };

  static MailSecurity fromJson(String? value) {
    if (value == null) return MailSecurity.sslOnConnect;
    switch (value.trim().toLowerCase()) {
      case 'none':
        return MailSecurity.none;
      case 'starttls':
        return MailSecurity.startTls;
      case 'sslonconnect':
      default:
        return MailSecurity.sslOnConnect;
    }
  }
}

enum MailFolderType {
  inbox,
  sent,
  drafts,
  trash,
  junk,
  archive,
  custom,
  unknown;

  String toJson() => switch (this) {
        MailFolderType.inbox => 'Inbox',
        MailFolderType.sent => 'Sent',
        MailFolderType.drafts => 'Drafts',
        MailFolderType.trash => 'Trash',
        MailFolderType.junk => 'Junk',
        MailFolderType.archive => 'Archive',
        MailFolderType.custom => 'Custom',
        MailFolderType.unknown => 'Unknown',
      };

  static MailFolderType fromJson(String? value) {
    if (value == null) return MailFolderType.unknown;
    switch (value.trim().toLowerCase()) {
      case 'inbox':
        return MailFolderType.inbox;
      case 'sent':
        return MailFolderType.sent;
      case 'drafts':
        return MailFolderType.drafts;
      case 'trash':
        return MailFolderType.trash;
      case 'junk':
        return MailFolderType.junk;
      case 'archive':
        return MailFolderType.archive;
      case 'custom':
        return MailFolderType.custom;
      default:
        return MailFolderType.unknown;
    }
  }
}
