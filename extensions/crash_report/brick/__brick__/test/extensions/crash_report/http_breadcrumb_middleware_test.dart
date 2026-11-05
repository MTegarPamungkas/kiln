import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/crash_report/http_breadcrumb_middleware.dart';

HttpRequest _request() {
  return HttpRequest(
    method: HttpMethod.get,
    uri: Uri.parse('https://api.test/v1/items?token=abc'),
    headers: const <String, String>{'Authorization': 'Bearer xyz'},
  );
}

void main() {
  group('HttpBreadcrumbMiddleware', () {
    test('records a success breadcrumb without headers or body', () async {
      final fake = FakeCrashReporter();
      final middleware = HttpBreadcrumbMiddleware(reporter: fake);

      final response = await middleware.handle(
        _request(),
        (request) async => const HttpResponse(statusCode: 200),
      );

      expect(response.statusCode, 200);
      final crumb = fake.breadcrumbs.single;
      expect(crumb.message, contains('HTTP GET'));
      expect(crumb.message, contains('200'));
      expect(crumb.data['status'], 200);
      expect(crumb.data['method'], 'GET');
      expect(crumb.data.containsKey('headers'), isFalse);
      expect(crumb.data.containsKey('body'), isFalse);
      expect(crumb.data['url'], isNot(contains('abc')));
    });

    test('records a failed breadcrumb and rethrows', () async {
      final fake = FakeCrashReporter();
      final middleware = HttpBreadcrumbMiddleware(reporter: fake);

      await expectLater(
        middleware.handle(
          _request(),
          (request) async {
            throw const Failure(
              code: FailureCode.networkTimeout,
              message: 'timeout',
              kind: FailureKind.network,
            );
          },
        ),
        throwsA(isA<Failure>()),
      );

      expect(fake.breadcrumbs.single.message, contains('failed'));
    });
  });
}
