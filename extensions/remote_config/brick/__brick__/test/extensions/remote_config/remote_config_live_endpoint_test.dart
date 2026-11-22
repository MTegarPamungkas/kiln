// Live endpoint coverage for `remote_config`.
//
// These tests open a real loopback HTTP server and use the real
// `HttpRemoteConfigGateway`, so the transport, JSON decoding, timeout mapping and
// the client's generation guard are exercised together. No external endpoint or
// credential is involved.
//
// The other suites use a fake gateway on purpose; this one exists to catch the
// gap between "the fake returns a map" and "package:http actually returns one".

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart' hide HttpRequest;
import 'package:{{app_name}}/extensions/remote_config/http_remote_config_gateway.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_client.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_config.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_module.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_support.dart';

void main() {
  group('remote config against a real endpoint', () {
    late _Endpoint endpoint;

    setUp(() async {
      endpoint = await _Endpoint.start();
    });

    tearDown(() async {
      await endpoint.close();
    });

    test('bootstrap fetches and activates over a real socket', () async {
      endpoint.body = <String, Object?>{'v': 3, 'beta': true};

      final registry = await KilnBootstrap.run(
        modules: <KilnModule>[
          RemoteConfigModule(config: _config(endpoint.url)),
        ],
      );

      expect(endpoint.requests, hasLength(1));
      expect(endpoint.requests.single, '/flags.json');
      final config = registry.read<RemoteConfig>();
      expect(config.getInt('v'), 3);
      expect(config.getBool('beta'), isTrue);

      await registry.read<Lifecycle>().dispose();
    });

    test('a superseded slow response cannot become active', () async {
      final gate = Completer<void>();
      var calls = 0;
      endpoint.handler = (HttpRequest request) async {
        calls += 1;
        if (calls == 1) {
          await gate.future;
          return <String, Object?>{'v': 1};
        }
        return <String, Object?>{'v': 2};
      };

      final client = RemoteConfigClient(
        config: _config(endpoint.url),
        gateway: HttpRemoteConfigGateway(),
      );

      final first = client.fetch();
      await endpoint.firstRequest.future;
      final second = client.fetch();
      gate.complete();
      await Future.wait(<Future<void>>[first, second]);

      client.activate();
      expect(calls, 2);
      expect(client.getInt('v'), 2);

      await client.close();
    });

    test('HTTP 500 maps to a typed failure and keeps the active values', () async {
      endpoint.body = <String, Object?>{'v': 1};

      final client = RemoteConfigClient(
        config: _config(endpoint.url),
        gateway: HttpRemoteConfigGateway(),
      );
      await client.fetchAndActivate();
      expect(client.getInt('v'), 1);

      endpoint.status = 500;
      await expectLater(
        client.fetchAndActivate(),
        throwsA(
          isA<Failure>().having(
            (Failure failure) => failure.code,
            'code',
            FailureCode.unavailable,
          ),
        ),
      );
      expect(client.getInt('v'), 1);

      await client.close();
    });

    test('a slow endpoint produces network.timeout', () async {
      endpoint
        ..body = <String, Object?>{'v': 9}
        ..delay = const Duration(milliseconds: 600);

      final client = RemoteConfigClient(
        config: _config(
          endpoint.url,
          requestTimeout: const Duration(milliseconds: 150),
        ),
        gateway: HttpRemoteConfigGateway(),
      );

      await expectLater(
        client.fetchAndActivate(),
        throwsA(
          isA<Failure>().having(
            (Failure failure) => failure.code,
            'code',
            FailureCode.networkTimeout,
          ),
        ),
      );

      await client.close();
    });

    test('a non-JSON body produces validation.invalid_input', () async {
      endpoint.rawBody = 'this is not json';

      final client = RemoteConfigClient(
        config: _config(endpoint.url),
        gateway: HttpRemoteConfigGateway(),
      );

      await expectLater(
        client.fetchAndActivate(),
        throwsA(
          isA<Failure>().having(
            (Failure failure) => failure.code,
            'code',
            FailureCode.validationInvalidInput,
          ),
        ),
      );

      await client.close();
    });

    test('an unreachable endpoint degrades to defaults, not a failed boot', () async {
      final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = probe.port;
      await probe.close(force: true);

      final registry = await KilnBootstrap.run(
        modules: <KilnModule>[
          RemoteConfigModule(
            config: _config('http://127.0.0.1:$port/flags.json'),
          ),
        ],
        supportTimeout: const Duration(seconds: 5),
      );

      expect(
        registry.read<RemoteConfig>().getString('missing', defaultValue: 'd'),
        'd',
      );
      final support = await registry.read<RemoteConfigSupport>().check();
      expect(support.state, SupportState.unavailable);

      await registry.read<Lifecycle>().dispose();
    });
  });
}

RemoteConfigConfig _config(
  String endpoint, {
  Duration requestTimeout = const Duration(seconds: 5),
}) {
  return RemoteConfigConfig(endpoint: endpoint, requestTimeout: requestTimeout);
}

/// Loopback endpoint whose response shape can change per test.
final class _Endpoint {
  _Endpoint._(this._server);

  final HttpServer _server;

  Map<String, Object?>? body = <String, Object?>{'v': 0};
  String? rawBody;
  int status = 200;
  Duration delay = Duration.zero;
  Future<Map<String, Object?>> Function(HttpRequest request)? handler;

  final List<String> requests = <String>[];
  final Completer<void> firstRequest = Completer<void>();

  String get url => 'http://127.0.0.1:${_server.port}/flags.json';

  static Future<_Endpoint> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final endpoint = _Endpoint._(server);
    server.listen(endpoint._handle);
    return endpoint;
  }

  Future<void> close() async {
    await _server.close(force: true);
    // Completing a listener that never fired keeps tearDown free of timeouts.
    if (!firstRequest.isCompleted) {
      firstRequest.complete();
    }
  }

  Future<void> _handle(HttpRequest request) async {
    requests.add(request.uri.path);
    if (!firstRequest.isCompleted) {
      firstRequest.complete();
    }
    try {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      final values = handler == null ? body : await handler!(request);
      request.response.statusCode = status;
      if (status >= 200 && status < 300) {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          rawBody ?? jsonEncode(values ?? <String, Object?>{}),
        );
      }
      await request.response.close();
    } on Object {
      // The client may close the socket while a delayed response is pending.
    }
  }
}
