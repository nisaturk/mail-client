enum UserRole { user, admin }

enum UserStatus { pending, active, disabled }

enum MailSecurity { none, sslOnConnect, startTls }

enum MailFolderType {
  inbox,
  sent,
  drafts,
  trash,
  junk,
  archive,
  custom,
  unknown,
}
