import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/crash_report/crash_report_failure_mapper.dart';

void main() {
  group('CrashReportFailureMapper', () {
    test('passes an existing Failure through unchanged', () {
      const failure = Failure(
        code: FailureCode.validationInvalidInput,
        message: 'keep me',
        kind: FailureKind.validation,
      );

      expect(const CrashReportFailureMapper().map(failure), same(failure));
    });

    test('wraps other errors as an unavailable failure', () {
      final failure = const CrashReportFailureMapper().map(
        StateError('sentry offline'),
      );

      expect(failure.kind, FailureKind.unavailable);
      expect(failure.code, FailureCode.unavailable);
    });
  });
}
