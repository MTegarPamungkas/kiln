import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/crash_report/gate_crash_report.dart';

Registry _registry(ConsentController consent, CrashReporter reporter) {
  return GetItRegistry()
    ..registerSingleton<ConsentController>(consent)
    ..registerSingleton<CrashReporter>(reporter);
}

void main() {
  group('GateCrashReportX', () {
    test('reportBreadcrumb records and returns Ok', () async {
      final fake = FakeCrashReporter();
      final consent = ConsentController()
        ..grant(ConsentCategory.crashReports);
      final gate = Gate(_registry(consent, fake));

      final result = await gate.reportBreadcrumb(
        'Opened profile',
        data: const {'tab': 'settings'},
      );

      expect(result, isA<Ok<void>>());
      expect(fake.breadcrumbs, hasLength(1));
      expect(fake.breadcrumbs.single.message, 'Opened profile');
    });

    test('setReportUser attaches and clears the user', () async {
      final fake = FakeCrashReporter();
      final gate = Gate(
        _registry(
          ConsentController()..grant(ConsentCategory.crashReports),
          fake,
        ),
      );

      await gate.setReportUser('user-1');
      expect(fake.userId, 'user-1');

      await gate.setReportUser(null);
      expect(fake.userId, isNull);
    });

    test('setReportContext forwards keyed context', () async {
      final fake = FakeCrashReporter();
      final gate = Gate(
        _registry(
          ConsentController()..grant(ConsentCategory.crashReports),
          fake,
        ),
      );

      await gate.setReportContext('cart', const {'items': 3});

      expect(fake.contexts['cart'], const <String, Object?>{'items': 3});
    });

    test('crashReportsConsented reflects the consent state', () {
      final consent = ConsentController();
      final gate = Gate(_registry(consent, FakeCrashReporter()));

      expect(gate.crashReportsConsented, isFalse);

      consent.grant(ConsentCategory.crashReports);
      expect(gate.crashReportsConsented, isTrue);
    });
  });
}
