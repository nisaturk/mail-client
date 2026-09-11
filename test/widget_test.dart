import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flapmail/main.dart';
import 'package:flapmail/presentation/screens/compose_screen.dart';
import 'package:flapmail/presentation/screens/home_screen.dart';
import 'package:flapmail/repositories/api_client.dart';

const _inboxItems = [
  {
    'id': '1',
    'mailAccountId': '1',
    'mailAccountEmail': 'ahmet@tekyazilim.com',
    'folderType': 'Inbox',
    'fromDisplayName': 'Mehmet Yilmaz',
    'fromAddress': 'mehmet@example.com',
    'subject': 'Proje Teslim Tarihi',
    'preview':
        'Proje teslim tarihi 15 Eylül olarak güncellendi. Lütfen güncel takvimi kontrol edin.',
    'receivedAt': '2025-09-10T09:00:00',
    'isRead': false,
    'hasAttachments': true,
  },
  {
    'id': '2',
    'mailAccountId': '1',
    'mailAccountEmail': 'ahmet@tekyazilim.com',
    'folderType': 'Inbox',
    'fromDisplayName': 'Zeynep Kaya',
    'fromAddress': 'zeynep@firma.com',
    'subject': 'Toplanti Notlari - 9 Eylül',
    'preview':
        'Toplantı notlarını paylaşıyorum: Bütçe görüşmesi gelecek haftaya ertelendi.',
    'receivedAt': '2025-09-10T08:00:00',
    'isRead': false,
    'hasAttachments': false,
  },
  {
    'id': '3',
    'mailAccountId': '2',
    'mailAccountEmail': 'destek@tekyazilim.com',
    'folderType': 'Inbox',
    'fromDisplayName': 'Destek Sistemi',
    'fromAddress': 'noreply@destek.com',
    'subject': 'Ticket #4821 Güncellendi',
    'preview': 'Ticket yeni bir güncelleme aldı. Durum: İnceleniyor.',
    'receivedAt': '2025-09-10T07:00:00',
    'isRead': true,
    'hasAttachments': false,
  },
  {
    'id': '4',
    'mailAccountId': '1',
    'mailAccountEmail': 'ahmet@tekyazilim.com',
    'folderType': 'Inbox',
    'fromDisplayName': 'Ali Demir',
    'fromAddress': 'ali@ortak.com',
    'subject': 'Fatura - Ağustos 2025',
    'preview': 'Ağustos ayı faturası ektedir. Ödeme vadesi: 20 Eylül 2025.',
    'receivedAt': '2025-09-09T09:00:00',
    'isRead': true,
    'hasAttachments': true,
  },
];

const _sentItems = [
  {
    'id': '5',
    'mailAccountId': '1',
    'mailAccountEmail': 'ahmet@tekyazilim.com',
    'folderType': 'Sent',
    'fromDisplayName': 'Ahmet',
    'fromAddress': 'ahmet@tekyazilim.com',
    'subject': 'Re: Proje Teslim Tarihi',
    'preview': 'Lütfen güncellenen teslim tarihi hakkında bilgi verir misiniz?',
    'receivedAt': '2025-09-10T10:00:00',
    'isRead': true,
    'hasAttachments': false,
  },
  {
    'id': '6',
    'mailAccountId': '2',
    'mailAccountEmail': 'destek@tekyazilim.com',
    'folderType': 'Sent',
    'fromDisplayName': 'Destek',
    'fromAddress': 'destek@tekyazilim.com',
    'subject': 'Re: Ticket #4821',
    'preview': 'İlgili kayıt incelendi, müşteri ile görüşme yapılacak.',
    'receivedAt': '2025-09-10T06:00:00',
    'isRead': true,
    'hasAttachments': false,
  },
];

const _accounts = [
  {
    'id': '1',
    'emailAddress': 'ahmet@tekyazilim.com',
    'displayName': 'Ahmet',
    'username': 'ahmet',
    'imapHost': 'imap.tekyazilim.com',
    'imapPort': 993,
    'imapSecurity': 'SslOnConnect',
    'smtpHost': 'smtp.tekyazilim.com',
    'smtpPort': 587,
    'smtpSecurity': 'StartTls',
    'saveSentCopy': true,
    'isActive': true,
    'createdAt': '2025-01-01T00:00:00',
    'updatedAt': '2025-06-01T00:00:00',
  },
];

const _detail4 = {
  'id': '4',
  'mailAccountId': '1',
  'mailAccountEmail': 'ahmet@tekyazilim.com',
  'folderType': 'Inbox',
  'fromDisplayName': 'Ali Demir',
  'fromAddress': 'ali@ortak.com',
  'toAddress': 'ahmet@tekyazilim.com',
  'subject': 'Fatura - Ağustos 2025',
  'receivedAt': '2025-09-09T09:00:00',
  'isRead': true,
  'hasAttachments': true,
  'bodyText': 'Ağustos ayı faturası ektedir. Ödeme vadesi: 20 Eylül 2025.',
  'attachments': [
    {
      'id': 'a3',
      'fileName': 'fatura_agustos_2025.pdf',
      'contentType': 'application/pdf',
      'sizeBytes': 156902,
      'isInline': false,
    },
  ],
};

/// Scripted API client for widget tests: serves canned JSON instead of the
/// live backend at [apiClientProvider.baseUrl].
class _ScriptedApiAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final method = options.method.toUpperCase();
    final uri = options.uri;
    final path = uri.path;

    ResponseBody json(Object data, {int status = 200}) => ResponseBody.fromString(
          jsonEncode(data),
          status,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );

    if (method == 'GET' && path == '/mail-accounts') {
      return json(_accounts);
    }
    if (method == 'GET' && path == '/mails') {
      final folder =
          (uri.queryParameters['folderType'] as String?) ?? 'Inbox';
      final items =
          folder.toLowerCase() == 'sent' ? _sentItems : _inboxItems;
      return json({'items': items, 'totalCount': items.length, 'page': 1, 'pageSize': 30});
    }
    if (method == 'GET' && path.startsWith('/mails/')) {
      final id = path.split('/').last;
      if (id == '4') return json(_detail4);
      return json({'error': 'not found'}, status: 404);
    }
    return json({'error': 'not found'}, status: 404);
  }

  @override
  void close({bool force = false}) {}
}

/// In-memory stand-in for [TokenStorage] so the auth interceptor never
/// touches a platform channel during widget tests.
class _FakeTokenStorage extends TokenStorage {
  String? _token;
  String? _userId;
  String? _email;
  String? _role;

  @override
  Future<String?> read() async => _token;
  @override
  Future<void> write(String token) async => _token = token;
  @override
  Future<void> delete() async => _token = null;
  @override
  Future<String?> readUserId() async => _userId;
  @override
  Future<void> writeUserId(String id) async => _userId = id;
  @override
  Future<String?> readEmail() async => _email;
  @override
  Future<void> writeEmail(String email) async => _email = email;
  @override
  Future<String?> readRole() async => _role;
  @override
  Future<void> writeRole(String role) async => _role = role;
  @override
  Future<void> clearAll() async {
    _token = null;
    _userId = null;
    _email = null;
    _role = null;
  }
}

ProviderScope _appScope({required Widget child}) {
  final client = ApiClient(tokenStorage: _FakeTokenStorage());
  client.dio.httpClientAdapter = _ScriptedApiAdapter();
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(client)],
    child: child,
  );
}

void main() {
  testWidgets('renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(_appScope(child: const MyApp()));
    await tester.pump();

    expect(find.text('FlapMail'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('home shows the inbox on a phone-sized surface',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _appScope(child: const MaterialApp(home: HomeScreen())),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Proje Teslim Tarihi'), findsOneWidget);
    expect(find.text('Mehmet Yilmaz'), findsOneWidget);
  });

  testWidgets('opening a mail shows the detail header', (WidgetTester tester) async {
    await tester.pumpWidget(
      _appScope(child: const MaterialApp(home: HomeScreen())),
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Fatura - Ağustos 2025'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Forward'), findsOneWidget);
  });

  testWidgets('search filters the mail list', (WidgetTester tester) async {
    await tester.pumpWidget(
      _appScope(child: const MaterialApp(home: HomeScreen())),
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Search mail'), findsOneWidget);
    expect(find.text('Ticket #4821 Güncellendi'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'fatura');
    await tester.pump();

    expect(find.text('Proje Teslim Tarihi'), findsNothing);
    expect(find.text('Fatura - Ağustos 2025'), findsWidgets);
  });

  testWidgets('compose renders on a narrow phone surface',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _appScope(child: const MaterialApp(home: ComposeScreen())),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('New message'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Subject'), findsOneWidget);
  });
}