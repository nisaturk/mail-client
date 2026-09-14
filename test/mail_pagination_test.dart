import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flapmail/models/enums.dart';
import 'package:flapmail/state/mail_provider.dart';

/// Scripted page-aware adapter: returns the canned items for the requested
/// `page` query parameter, with a fixed [totalCount].
class _PaginatedAdapter implements HttpClientAdapter {
  _PaginatedAdapter(this.pages, this.totalCount);

  final Map<int, List<Map<String, dynamic>>> pages;
  final int totalCount;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    final page = int.parse(options.uri.queryParameters['page']!);
    final items = pages[page] ?? <Map<String, dynamic>>[];
    return ResponseBody.fromString(
      jsonEncode({
        'items': items,
        'totalCount': totalCount,
        'page': page,
      }),
      200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _item(String id) => {
      'id': id,
      'mailAccountId': '1',
      'mailAccountEmail': 'test@example.com',
      'folderType': 'Inbox',
      'fromDisplayName': 'Sender $id',
      'fromAddress': 'sender$id@example.com',
      'subject': 'Mail $id',
      'receivedAt': '2025-09-10T09:00:00',
      'isRead': false,
      'hasAttachments': false,
    };

Dio _dioWith(_PaginatedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  group('MailListNotifier pagination', () {
    test('loading the next page appends messages', () async {
      final adapter = _PaginatedAdapter({
        1: [_item('1'), _item('2')],
        2: [_item('3'), _item('4')],
      }, 4);
      final notifier = MailListNotifier(dio: _dioWith(adapter));

      await notifier.load(folderType: MailFolderType.inbox);
      expect(notifier.state.mails.map((m) => m.id), ['1', '2']);
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.page, 2);

      await notifier.loadMore();
      expect(notifier.state.mails.map((m) => m.id), ['1', '2', '3', '4']);
      expect(notifier.state.hasMore, isFalse);
    });

    test('duplicate messages are not added when pages overlap', () async {
      final adapter = _PaginatedAdapter({
        1: [_item('1'), _item('2')],
        2: [_item('2'), _item('3')],
      }, 3);
      final notifier = MailListNotifier(dio: _dioWith(adapter));

      await notifier.load(folderType: MailFolderType.inbox);
      await notifier.loadMore();

      expect(notifier.state.mails.map((m) => m.id), ['1', '2', '3']);
      expect(notifier.state.totalCount, 3);
      expect(notifier.state.hasMore, isFalse);
    });

    test('hasMore and totalCount are derived from cumulative length', () async {
      final adapter = _PaginatedAdapter({
        1: [_item('1'), _item('2')],
        2: [_item('3')],
      }, 3);
      final notifier = MailListNotifier(dio: _dioWith(adapter));

      await notifier.load(folderType: MailFolderType.inbox);
      expect(notifier.state.hasMore, isTrue); // 2 loaded < 3 total

      await notifier.loadMore();
      expect(notifier.state.mails, hasLength(3));
      expect(notifier.state.hasMore, isFalse); // 3 loaded == 3 total
      expect(notifier.state.totalCount, 3);
    });

    test('loading another page does not replace existing messages', () async {
      final adapter = _PaginatedAdapter({
        1: [_item('1'), _item('2')],
        2: [_item('3'), _item('4'), _item('5')],
      }, 5);
      final notifier = MailListNotifier(dio: _dioWith(adapter));

      await notifier.load(folderType: MailFolderType.inbox);
      final first = notifier.state.mails.first;
      await notifier.loadMore();

      expect(notifier.state.mails, hasLength(5));
      expect(notifier.state.mails.first.id, first.id);
    });

    test('no API call when there are no more pages', () async {
      final adapter = _PaginatedAdapter({
        1: [_item('1'), _item('2')],
      }, 2);
      final notifier = MailListNotifier(dio: _dioWith(adapter));

      await notifier.load(folderType: MailFolderType.inbox);
      expect(notifier.state.hasMore, isFalse);
      final callsAfterLoad = adapter.calls;

      await notifier.loadMore();
      expect(adapter.calls, callsAfterLoad, reason: 'loadMore must not fetch');
    });
  });
}