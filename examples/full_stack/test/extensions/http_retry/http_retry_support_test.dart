import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/http_retry/http_retry_support.dart';
import 'package:full_stack/extensions/http_retry/retry_settings.dart';

void main() {
  test('reports supported for valid retry settings', () {
    const support = HttpRetrySupport(
      settings: HttpRetrySettings(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 250),
        maxDelay: Duration(seconds: 8),
      ),
    );

    expect(support.info.isSupported, isTrue);
    expect(support.info.details['max_attempts'], 3);
  });

  test('rejects a zero attempt count', () {
    const support = HttpRetrySupport(
      settings: HttpRetrySettings(maxAttempts: 0),
    );

    expect(support.info.state, SupportState.notConfigured);
    expect(support.info.toFailure().code, FailureCode.configurationMissing);
  });

  test('rejects maxDelay below initialDelay', () {
    const support = HttpRetrySupport(
      settings: HttpRetrySettings(
        maxAttempts: 2,
        initialDelay: Duration(seconds: 5),
        maxDelay: Duration(seconds: 1),
      ),
    );

    expect(support.info.state, SupportState.notConfigured);
    expect(support.info.toFailure().kind, FailureKind.configuration);
  });

  test('rejects negative delays', () {
    const support = HttpRetrySupport(
      settings: HttpRetrySettings(
        maxAttempts: 2,
        initialDelay: Duration(milliseconds: -1),
      ),
    );

    expect(support.info.isSupported, isFalse);
  });
}
