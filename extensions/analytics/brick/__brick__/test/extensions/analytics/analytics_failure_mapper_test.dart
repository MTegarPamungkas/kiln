import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_failure_mapper.dart';

void main() {
  const mapper = AnalyticsFailureMapper();

  test('maps plugin errors to Failure(unavailable)', () {
    final error = StateError('posthog down');
    final stackTrace = StackTrace.current;

    final failure = mapper.map(error, stackTrace: stackTrace);

    expect(failure.code, FailureCode.unavailable);
    expect(failure.kind, FailureKind.unavailable);
    expect(failure.cause, same(error));
    expect(failure.stackTrace, same(stackTrace));
    expect(failure.message, contains('posthog down'));
  });

  test('keeps an existing Failure unchanged', () {
    const original = Failure(
      code: FailureCode.validationUnsupportedValue,
      message: 'bad property',
      kind: FailureKind.validation,
    );

    expect(mapper.map(original), same(original));
  });
}
