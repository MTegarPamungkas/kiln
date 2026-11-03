import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_config.dart';

void main() {
  test('defaults carry the rendered install prompts', () {
    const config = FirebaseConfig.defaults;

    expect(config.optionsSource, FirebaseOptionsSource.generated);
    expect(config.firebaseOptionsPath, 'lib/firebase_options.dart');
    expect(config.emulatorHost, 'localhost');
    expect(config.useEmulatorInDevelopment, isTrue);
    expect(config.ports.auth, 9099);
    expect(config.ports.firestore, 8080);
    expect(config.ports.storage, 9199);
  });

  test('development flavor uses the emulator', () {
    const config = FirebaseConfig.defaults;

    expect(config.shouldUseEmulator(AppFlavor.development), isTrue);
    expect(config.shouldUseEmulator(AppFlavor.staging), isFalse);
    expect(config.shouldUseEmulator(AppFlavor.production), isFalse);
  });

  test('the emulator flag can be disabled for development', () {
    const config = FirebaseConfig(useEmulatorInDevelopment: false);

    expect(config.shouldUseEmulator(AppFlavor.development), isFalse);
  });

  test('explicit options source and emulator host are typed values', () {
    const config = FirebaseConfig(
      optionsSource: FirebaseOptionsSource.explicit,
      emulatorHost: '10.0.2.2',
    );

    expect(config.optionsSource, FirebaseOptionsSource.explicit);
    expect(config.emulatorHost, '10.0.2.2');
  });

  test('copyWith overrides only the requested fields', () {
    final config = FirebaseConfig.defaults.copyWith(
      emulatorHost: '192.168.1.10',
      ports: const FirebaseEmulatorPorts(auth: 1009),
    );

    expect(config.emulatorHost, '192.168.1.10');
    expect(config.ports.auth, 1009);
    expect(config.ports.firestore, 8080);
    expect(config.optionsSource, FirebaseOptionsSource.generated);
  });
}
