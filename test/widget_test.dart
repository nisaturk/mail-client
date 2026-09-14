import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flapmail/main.dart';
import 'package:flapmail/models/enums.dart';
import 'package:flapmail/models/mail_detail.dart';
import 'package:flapmail/models/mail_summary.dart';
import 'package:flapmail/presentation/screens/compose_screen.dart';
import 'package:flapmail/presentation/screens/home_screen.dart';
import 'package:flapmail/repositories/api_client.dart';
import 'package:flapmail/state/mail_accounts_provider.dart';
import 'package:flapmail/state/mail_provider.dart';

final _inboxMails = [
  MailSummary(
    id: '1',
    mailAccountId: '1',
    mailAccountEmail: 'ahmet@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Mehmet Yilmaz',
    fromAddress: 'mehmet@example.com',
    subject: 'Proje Teslim Tarihi',
    preview: 'Proje teslim tarihi 15 Eylül olarak güncellendi.',
    receivedAt: DateTime(2025, 9, 10, 9),
    isRead: false,
    hasAttachments: true,
  ),
  MailSummary(
    id: '2',
    mailAccountId: '1',
    mailAccountEmail: 'ahmet@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Zeynep Kaya',
    fromAddress: 'zeynep@firma.com',
    subject: 'Toplanti Notlari - 9 Eylül',
    preview: 'Toplantı notlarını paylaşıyorum.',
    receivedAt: DateTime(2025, 9, 10, 8),
    isRead: false,
    hasAttachments: false,
  ),
  MailSummary(
    id: '3',
    mailAccountId: '2',
    mailAccountEmail: 'destek@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Destek Sistemi',
    fromAddress: 'noreply@destek.com',
    subject: 'Ticket #4821 Güncellendi',
    preview: 'Ticket yeni bir güncelleme aldı.',
    receivedAt: DateTime(2025, 9, 10, 7),
    isRead: true,
    hasAttachments: false,
  ),
  MailSummary(
    id: '4',
    mailAccountId: '1',
    mailAccountEmail: 'ahmet@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Ali Demir',
    fromAddress: 'ali@ortak.com',
    subject: 'Fatura - Ağustos 2025',
    preview: 'Ağustos ayı faturası ektedir.',
    receivedAt: DateTime(2025, 9, 9, 9),
    isRead: true,
    hasAttachments: true,
  ),
];

const _detail4Json = {
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
  'bodyText': 'Ağustos ayı faturası ektedir.',
  'attachments': <dynamic>[],
};

/// A MailListNotifier that skips all Dio calls and holds pre-loaded state.
class _FakeMailListNotifier extends MailListNotifier {
  _FakeMailListNotifier(MailListState initial) : super(dio: null) {
    state = initial;
  }

  @override
  Future<void> load({String? accountId, MailFolderType? folderType}) async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<MailDetail?> fetchDetail(String mailId) async {
    if (mailId == '4') return MailDetail.fromJson(_detail4Json);
    return null;
  }
}

/// A MailAccountsNotifier that skips Dio calls.
class _FakeMailAccountsNotifier extends MailAccountsNotifier {
  _FakeMailAccountsNotifier() : super(dio: null);
}

MailListState _loadedState({String? searchQuery}) {
  return MailListState(
    mails: _inboxMails,
    page: 2,
    totalCount: _inboxMails.length,
    hasMore: false,
    searchQuery: searchQuery,
  );
}

ProviderScope _appScope({required Widget child, MailListState? mailState}) {
  final client = ApiClient(tokenStorage: _FakeTokenStorage());
  final state = mailState ?? _loadedState();
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(client),
      mailListProvider.overrideWith((ref) =>
          _FakeMailListNotifier(state)),
      mailAccountsProvider.overrideWith((ref) => _FakeMailAccountsNotifier()),
    ],
    child: child,
  );
}

class _FakeTokenStorage extends TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;
  @override
  Future<void> write(String token) async => _token = token;
  @override
  Future<void> delete() async => _token = null;
  @override
  Future<String?> readUserId() async => null;
  @override
  Future<void> writeUserId(String id) async {}
  @override
  Future<String?> readEmail() async => null;
  @override
  Future<void> writeEmail(String email) async {}
  @override
  Future<void> clearAll() async => _token = null;
}

void main() {
  testWidgets('renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(
              ApiClient(tokenStorage: _FakeTokenStorage())),
        ],
        child: const MyApp(),
      ),
    );
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
    await tester.pump();

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Proje Teslim Tarihi'), findsOneWidget);
    expect(find.text('Mehmet Yilmaz'), findsOneWidget);
  });

  testWidgets('opening a mail shows the detail header',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _appScope(child: const MaterialApp(home: HomeScreen())),
    );
    await tester.pump();

    await tester.tap(find.text('Fatura - Ağustos 2025'));
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Forward'), findsOneWidget);
  });

  testWidgets('search filters the mail list', (WidgetTester tester) async {
    await tester.pumpWidget(
      _appScope(child: const MaterialApp(home: HomeScreen())),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

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
    await tester.pump();

    expect(find.text('New message'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Subject'), findsOneWidget);
  });
}
