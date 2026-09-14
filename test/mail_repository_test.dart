import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flapmail/repositories/api_config.dart';
import 'package:flapmail/repositories/mail_repository.dart';

/// Scripted [HttpClientAdapter] that records every request and lets the test
/// decide the response (or throw). No real network is touched.
class _ScriptedSendAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Future<ResponseBody> Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler!(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );

Dio _dioWith(_ScriptedSendAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  group('sendMail', () {
    test('successful send returns sent=true and no warning', () async {
      final adapter = _ScriptedSendAdapter()
        ..handler = (_) async => _json({'sent': true, 'sentCopySaved': true});
      final result = await sendMail(
        dio: _dioWith(adapter),
        accountId: 'acc-1',
        toAddress: 'a@b.com',
        subject: 'Hello',
        bodyText: 'Body',
        idempotencyKey: 'key-1',
      );

      expect(result.sent, isTrue);
      expect(result.sentCopySaved, isTrue);
      expect(result.warning, isNull);
      expect(result.deliveryUncertain, isFalse);
      expect(result.retryable, isFalse);
      expect(result.error, isNull);

      expect(adapter.requests, hasLength(1));
      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.path, '/mail-accounts/acc-1/send');
      expect(req.headers['Idempotency-Key'], 'key-1');
      final fields = (req.data as FormData).fields;
      String field(String name) =>
          fields.firstWhere((e) => e.key == name).value;
      expect(field('toAddress'), 'a@b.com');
      expect(field('subject'), 'Hello');
      expect(field('bodyText'), 'Body');
    });

    test('send success but sent copy not saved surfaces warning', () async {
      final adapter = _ScriptedSendAdapter()
        ..handler = (_) async => _json({
              'sent': true,
              'sentCopySaved': false,
              'warning': 'Sent copy folder missing',
            });
      final result = await sendMail(
        dio: _dioWith(adapter),
        accountId: 'acc-1',
        toAddress: 'a@b.com',
        subject: 'Hi',
        idempotencyKey: 'key-2',
      );

      expect(result.sent, isTrue);
      expect(result.sentCopySaved, isFalse);
      expect(result.warning, 'Sent copy folder missing');
    });

    test('complete failure returns error and sent=false (400)', () async {
      final adapter = _ScriptedSendAdapter()
        ..handler = (_) async =>
            _json({'message': 'SMTP rejected the sender'}, status: 400);
      final result = await sendMail(
        dio: _dioWith(adapter),
        accountId: 'acc-1',
        toAddress: 'a@b.com',
        subject: 'Hi',
        idempotencyKey: 'key-3',
      );

      expect(result.sent, isFalse);
      expect(result.error, 'SMTP rejected the sender');
      expect(result.retryable, isFalse);
      expect(result.deliveryUncertain, isFalse);
    });

    test('409 marks delivery as uncertain', () async {
      final adapter = _ScriptedSendAdapter()
        ..handler = (_) async =>
            _json({'message': 'duplicate key'}, status: 409);
      final result = await sendMail(
        dio: _dioWith(adapter),
        accountId: 'acc-1',
        toAddress: 'a@b.com',
        subject: 'Hi',
        idempotencyKey: 'key-4',
      );

      expect(result.sent, isFalse);
      expect(result.deliveryUncertain, isTrue);
      expect(result.error, contains('check your mailbox'));
    });

    test('502 is retryable', () async {
      final adapter = _ScriptedSendAdapter()
        ..handler = (_) async =>
            _json({'message': 'upstream failed'}, status: 502);
      final result = await sendMail(
        dio: _dioWith(adapter),
        accountId: 'acc-1',
        toAddress: 'a@b.com',
        subject: 'Hi',
        idempotencyKey: 'key-5',
      );

      expect(result.sent, isFalse);
      expect(result.retryable, isTrue);
      expect(result.error, contains('Try sending again'));
    });

    test('connection error (no response) is retryable', () async {
      final adapter = _ScriptedSendAdapter()
        ..handler = (options) async =>
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'network unreachable',
            );
      final result = await sendMail(
        dio: _dioWith(adapter),
        accountId: 'acc-1',
        toAddress: 'a@b.com',
        subject: 'Hi',
        idempotencyKey: 'key-6',
      );

      expect(result.sent, isFalse);
      expect(result.retryable, isTrue);
      expect(result.error, contains('Could not reach the server'));
    });

    test('idempotency key is passed through verbatim per send', () async {
      final adapter = _ScriptedSendAdapter()
        ..handler = (_) async => _json({'sent': true});
      final dio = _dioWith(adapter);

      await sendMail(
        dio: dio,
        accountId: 'acc-1',
        toAddress: 'a@b.com',
        subject: 'A',
        idempotencyKey: 'key-first',
      );
      // Same logical send retried → same key.
      await sendMail(
        dio: dio,
        accountId: 'acc-1',
        toAddress: 'a@b.com',
        subject: 'A',
        idempotencyKey: 'key-first',
      );

      expect(adapter.requests, hasLength(2));
      expect(
        adapter.requests.map((r) => r.headers['Idempotency-Key']).toList(),
        ['key-first', 'key-first'],
      );
    });

    test('a brand new send gets a distinct key (passed from UI)', () async {
      final adapter = _ScriptedSendAdapter()
        ..handler = (_) async => _json({'sent': true});
      final dio = _dioWith(adapter);

      await sendMail(
        dio: dio,
        accountId: 'acc-1',
        toAddress: 'a@b.com',
        subject: 'A',
        idempotencyKey: 'key-new-1',
      );
      await sendMail(
        dio: dio,
        accountId: 'acc-1',
        toAddress: 'a@b.com',
        subject: 'A',
        idempotencyKey: 'key-new-2',
      );

      final keys =
          adapter.requests.map((r) => r.headers['Idempotency-Key']).toList();
      expect(keys, ['key-new-1', 'key-new-2']);
      expect(keys[0], isNot(keys[1]));
    });
  });
}