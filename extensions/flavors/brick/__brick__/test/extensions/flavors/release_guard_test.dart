import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/flavors/release_guard.dart';

void main() {
  test('warns for a release build with a non-production flavor', () {
    final logger = RecordingLogger();
    const guard = ReleaseGuard(
      flavor: AppFlavor.staging,
      isRelease: true,
      isDebug: false,
    );

    guard.report(logger);

    expect(logger.levels, [LogLevel.warning]);
    expect(logger.messages.single, contains('staging'));
  });

  test('stays quiet for production or debug builds', () {
    final logger = RecordingLogger();

    const ReleaseGuard(
      flavor: AppFlavor.production,
      isRelease: true,
      isDebug: false,
    ).report(logger);
    const ReleaseGuard(
      flavor: AppFlavor.development,
      isRelease: false,
      isDebug: true,
    ).report(logger);

    expect(logger.records, isEmpty);
  });
}
