import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/connectivity/offline_guard_middleware.dart';

void main() {
  test('fails fast while offline', () async {
    final monitor = FakeConnectivity(initial: NetworkStatus.offline);
    final middleware = OfflineGuardMiddleware(monitor);
    var calls = 0;

    await expectLater(
      middleware.handle(
        HttpRequest(
          method: HttpMethod.get,
          uri: Uri.parse('https://api.kiln.dev'),
        ),
        (_) async {
          calls++;
          return const HttpResponse(statusCode: 200);
        },
      ),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.networkOffline,
        ),
      ),
    );
    expect(calls, 0);
  });

  test('passes through while online', () async {
    final monitor = FakeConnectivity(initial: NetworkStatus.online);
    final middleware = OfflineGuardMiddleware(monitor);

    final response = await middleware.handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev'),
      ),
      (_) async => const HttpResponse(statusCode: 200),
    );

    expect(response.statusCode, 200);
  });
}
