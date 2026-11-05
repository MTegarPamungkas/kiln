import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/logger/log_level_controller.dart';

void main() {
  test('non-production flavors can change the level', () {
    final changes = <LogLevel>[];
    final controller = LogLevelController(
      initialLevel: LogLevel.info,
      flavor: AppFlavor.staging,
      onChanged: changes.add,
    );

    controller.setLevel(LogLevel.trace);

    expect(controller.level, LogLevel.trace);
    expect(changes, <LogLevel>[LogLevel.trace]);
    expect(controller.canChange, isTrue);
  });

  test('production ignores a change by throwing a documented failure', () {
    final controller = LogLevelController(
      initialLevel: LogLevel.warning,
      flavor: AppFlavor.production,
    );

    expect(
      () => controller.setLevel(LogLevel.trace),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.validationUnsupportedValue,
        ),
      ),
    );
    expect(controller.level, LogLevel.warning);
    expect(controller.canChange, isFalse);
  });

  test('setting the same level does not notify', () {
    var calls = 0;
    final controller = LogLevelController(
      initialLevel: LogLevel.debug,
      flavor: AppFlavor.development,
      onChanged: (level) => calls++,
    );

    controller.setLevel(LogLevel.debug);

    expect(calls, 0);
  });
}
