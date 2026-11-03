import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_app.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_config.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_support.dart';

final class _FakeInitializer implements FirebaseAppInitializer {
  _FakeInitializer({this.error});

  final Object? error;
  int calls = 0;

  @override
  Future<void> initialize() async {
    calls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }
}

void main() {
  test('reports supported when Firebase initializes', () async {
    final initializer = _FakeInitializer();
    final support = FirebaseSupport(
      initializer: initializer,
      config: const FirebaseConfig(),
      flavor: AppFlavor.production,
    );

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(info.details['options_source'], 'generated');
    expect(info.details['emulator'], isFalse);
    expect(initializer.calls, 1);
  });

  test('reports missing options as not configured', () async {
    final support = FirebaseSupport(
      initializer: _FakeInitializer(
        error: const Failure(
          code: FailureCode.configurationMissing,
          message: 'FirebaseOptions belum diberikan.',
          kind: FailureKind.configuration,
        ),
      ),
      config: const FirebaseConfig(),
      flavor: AppFlavor.production,
    );

    final info = await support.check();

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().code, FailureCode.configurationMissing);
  });

  test('maps initialization errors to unavailable', () async {
    final support = FirebaseSupport(
      initializer: _FakeInitializer(error: StateError('native init failed')),
      config: const FirebaseConfig(),
      flavor: AppFlavor.development,
    );

    final info = await support.check();

    expect(info.state, SupportState.unavailable);
    expect(info.toFailure().code, FailureCode.unavailable);
  });

  test('caches the probe until cleared', () async {
    final initializer = _FakeInitializer();
    final support = FirebaseSupport(
      initializer: initializer,
      config: const FirebaseConfig(),
      flavor: AppFlavor.production,
    );

    await support.check();
    await support.check();
    expect(initializer.calls, 1);

    support.clear();
    await support.check();
    expect(initializer.calls, 2);
  });
}
