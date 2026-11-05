import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/connectivity/reachability_probe.dart';

void main() {
  const probe = ReachabilityProbe();
  final uri = Uri.parse('https://api.kiln.dev/health');

  test('uses the HttpClient contract when available', () async {
    final client = FakeHttpClient(
      defaultResponse: const HttpResponse(statusCode: 204),
    );

    expect(await probe.probe(client, uri), isTrue);
    expect(client.requests.single.method, HttpMethod.head);
  });

  test('returns true without a client and false on errors', () async {
    expect(await probe.probe(null, uri), isTrue);

    final failing = FakeHttpClient(
      failure: const Failure(
        code: FailureCode.networkUnreachable,
        message: 'unreachable',
        kind: FailureKind.network,
      ),
    );
    expect(await probe.probe(failing, uri), isFalse);
  });
}
