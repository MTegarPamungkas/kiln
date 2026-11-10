import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/logger/http_log_middleware.dart';
import 'package:full_stack/extensions/logger/log_sink.dart';
import 'package:full_stack/extensions/logger/memory_log_sink.dart';
import 'package:full_stack/extensions/logger/sink_pipeline.dart';

void main() {
  test('logs method, sanitized URL, status, and duration', () async {
    final memory = MemoryLogSink();
    final clock = FixedClock(DateTime.utc(2026, 3, 4, 5, 6));
    final logger = PipelineLogger(
      pipeline: SinkPipeline(<LogSink>[memory]),
      clock: clock,
    );
    final client = FakeHttpClient(
      onRequest: (request) async {
        clock.advance(const Duration(milliseconds: 42));
        return const HttpResponse(statusCode: 201);
      },
    );
    final pipeline = HttpPipeline(<HttpMiddleware>[
      HttpLogMiddleware(logger: logger, clock: clock),
    ]);

    final response = await pipeline.execute(
      HttpRequest(
        method: HttpMethod.post,
        uri: Uri.parse('https://user:pass@api.example.com/users?token=abc'),
        headers: const <String, String>{
          'Authorization': 'Bearer super-secret',
          'Content-Type': 'application/json',
        },
        body: '{"password":"hunter2"}',
      ),
      client.send,
    );

    expect(response.statusCode, 201);
    final record = memory.records.single;
    expect(record.level, LogLevel.info);
    expect(record.message, contains('POST'));
    expect(record.message, contains('api.example.com/users'));
    expect(record.message, contains('201'));
    expect(record.message, contains('42 ms'));
    expect(record.message, isNot(contains('super-secret')));
    expect(record.message, isNot(contains('hunter2')));
    expect(record.message, isNot(contains('user:pass')));
    expect(record.message, isNot(contains('token=abc')));
    expect(record.data?['status'], 201);
    expect(record.data?['duration_ms'], 42);
    final headers = record.data?['headers'] as Map<String, String>;
    expect(headers['Authorization'], '[redacted]');
    expect(headers['Content-Type'], 'application/json');
  });

  test('4xx responses log a warning and 5xx an error', () async {
    final memory = MemoryLogSink();
    final logger = PipelineLogger(pipeline: SinkPipeline(<LogSink>[memory]));
    var status = 404;
    final client = FakeHttpClient(
      onRequest: (request) async => HttpResponse(statusCode: status),
    );
    final middleware = HttpLogMiddleware(logger: logger);

    await middleware.handle(_request(), client.send);
    status = 503;
    await middleware.handle(_request(), client.send);

    expect(memory.records.map((record) => record.level), <LogLevel>[
      LogLevel.warning,
      LogLevel.error,
    ]);
  });

  test('logs failures and rethrows them unchanged', () async {
    const failure = Failure(
      code: FailureCode.networkOffline,
      message: 'offline',
      kind: FailureKind.network,
    );
    final memory = MemoryLogSink();
    final logger = PipelineLogger(pipeline: SinkPipeline(<LogSink>[memory]));
    final middleware = HttpLogMiddleware(logger: logger);
    final client = FakeHttpClient(failure: failure);

    await expectLater(
      middleware.handle(_request(), client.send),
      throwsA(same(failure)),
    );

    final record = memory.records.single;
    expect(record.level, LogLevel.error);
    expect(record.error, same(failure));
    expect(record.message, contains('failed'));
    expect(record.data?.containsKey('status'), isFalse);
    expect(record.data?['method'], 'GET');
  });
}

HttpRequest _request() {
  return HttpRequest(
    method: HttpMethod.get,
    uri: Uri.parse('https://api.example.com/profile'),
    headers: const <String, String>{'Authorization': 'Bearer secret'},
    body: '{"pin":"1234"}',
  );
}
