import 'package:flutter_test/flutter_test.dart';

import 'package:flapmail/models/enums.dart';
import 'package:flapmail/models/mail_account.dart';
import 'package:flapmail/models/mail_detail.dart';
import 'package:flapmail/models/mail_summary.dart';
import 'package:flapmail/models/user.dart';

void main() {
  group('MailSummary', () {
    test('parses preview from preview or snippet', () {
      final fromPreview = MailSummary.fromJson(_summaryJson(preview: 'Hi'));
      final fromSnippet = MailSummary.fromJson(_summaryJson(snippet: 'Hello'));
      expect(fromPreview.preview, 'Hi');
      expect(fromSnippet.preview, 'Hello');
    });

    test('falls back to defaults and unknown folder', () {
      final summary = MailSummary.fromJson({
        'id': '9',
        'mailAccountId': '1',
        'folderType': 'whatever',
        'fromDisplayName': null,
        'subject': null,
        'receivedAt': '2026-09-11T10:00:00',
      });
      expect(summary.folderType, MailFolderType.unknown);
      expect(summary.fromDisplayName, '');
      expect(summary.subject, '(no subject)');
      expect(summary.isRead, false);
    });

    test('copyWith overrides only the given fields', () {
      final summary = MailSummary.fromJson(_summaryJson(preview: 'Hi'));
      final read = summary.copyWith(isRead: true, preview: 'New');
      expect(read.isRead, true);
      expect(read.preview, 'New');
      expect(read.id, summary.id);
      expect(read.fromAddress, summary.fromAddress);
    });
  });

  group('MailAccount', () {
    test('parses security with fallback and defaults', () {
      final account = MailAccount.fromJson({
        'id': '1',
        'emailAddress': 'a@b.com',
        'imapHost': 'imap.b.com',
        'imapPort': 993,
        'imapSecurity': 'bogus',
        'smtpHost': 'smtp.b.com',
        'smtpPort': 587,
        'createdAt': '2026-01-01T00:00:00',
        'updatedAt': '2026-01-02T00:00:00',
      });
      expect(account.imapSecurity, MailSecurity.sslOnConnect);
      expect(account.smtpSecurity, MailSecurity.sslOnConnect);
      expect(account.displayName, '');
      expect(account.isActive, true);
    });

    test('copyWith keeps untouched fields', () {
      final account = MailAccount.fromJson({
        'id': '1',
        'emailAddress': 'a@b.com',
        'imapHost': 'imap.b.com',
        'imapPort': 993,
        'imapSecurity': 'sslOnConnect',
        'smtpHost': 'smtp.b.com',
        'smtpPort': 587,
        'smtpSecurity': 'sslOnConnect',
        'saveSentCopy': true,
        'createdAt': '2026-01-01T00:00:00',
        'updatedAt': '2026-01-02T00:00:00',
      });
      final disabled = account.copyWith(isActive: false);
      expect(disabled.isActive, false);
      expect(disabled.emailAddress, 'a@b.com');
      expect(disabled.smtpPort, 587);
    });
  });

  group('User', () {
    test('parses role and status with fallbacks', () {
      final user = User.fromJson({
        'id': '1',
        'email': 'u@b.com',
        'role': 'boss',
        'status': null,
        'createdAt': '2026-01-01T00:00:00',
        'lastLoginAt': null,
      });
      expect(user.role, UserRole.user);
      expect(user.status, UserStatus.pending);
      expect(user.lastLoginAt, null);
    });

    test('copyWith overrides only the given fields', () {
      final user = User.fromJson({
        'id': '1',
        'email': 'u@b.com',
        'role': 'user',
        'status': 'active',
        'createdAt': '2026-01-01T00:00:00',
      });
      final promoted = user.copyWith(role: UserRole.admin);
      expect(promoted.role, UserRole.admin);
      expect(promoted.status, UserStatus.active);
      expect(promoted.email, 'u@b.com');
    });
  });

  group('MailDetail', () {
    test('defaults body and attachments when missing', () {
      final detail = MailDetail.fromJson({
        'id': '1',
        'mailAccountId': '1',
        'folderType': 'inbox',
        'fromDisplayName': 'M',
        'fromAddress': 'm@x.com',
        'toAddress': 't@x.com',
        'subject': 'S',
        'receivedAt': '2026-01-01T00:00:00',
      });
      expect(detail.bodyHtml, '');
      expect(detail.bodyText, '');
      expect(detail.attachments, isEmpty);
    });
  });
}

Map<String, dynamic> _summaryJson({String? preview, String? snippet}) {
  return {
    'id': '1',
    'mailAccountId': '1',
    'folderType': 'inbox',
    'fromDisplayName': 'Mehmet',
    'fromAddress': 'm@x.com',
    'subject': 'Hello',
    if (preview != null) 'preview': preview,
    if (snippet != null) 'snippet': snippet,
    'receivedAt': '2026-09-11T10:00:00',
    'isRead': true,
    'hasAttachments': true,
  };
}