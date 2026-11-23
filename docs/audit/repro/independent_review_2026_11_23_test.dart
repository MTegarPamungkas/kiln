// Regression checks for the findings in the independent review.
import 'dart:async';
import 'dart:io';

import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

final class _Module extends KilnModule {
  _Module(
    this.id, {
    this.provides = const {},
    this.requires = const {},
    this.optionalRequires = const {},
    this.platforms = const {},
    this.requiredForStartup = false,
    this.info = const SupportInfo.supported(),
  });

  @override
  final String id;
  @override
  final Set<String> provides;
  @override
  final Set<String> requires;
  @override
  final Set<String> optionalRequires;
  @override
  final Set<String> platforms;
  @override
  final bool requiredForStartup;
  final SupportInfo info;
  bool becameReady = false;

  @override
  void register(Registry registry) {}
  @override
  SupportInfo support(Registry registry) => info;
  @override
  void ready(Registry registry) => becameReady = true;
}

void main() {
  test('N1: a filtered provider degrades the optional consumer', () async {
    final consumer = _Module('consumer', requires: {'http'});
    final registry = await KilnBootstrap.run(
      platform: 'android',
      modules: [
        _Module('provider', provides: {'http'}, platforms: {'web'}),
        consumer,
      ],
    );
    addTearDown(registry.read<Lifecycle>().dispose);
    expect(consumer.becameReady, isFalse);
    expect(
      registry.read<SupportRegistry>()['consumer']?.state,
      SupportState.unavailable,
    );
  });

  test('N1 related: required platform rejection has a typed failure', () async {
    await expectLater(
      KilnBootstrap.run(
        platform: 'android',
        modules: [
          _Module('required', platforms: {'web'}, requiredForStartup: true),
        ],
      ),
      throwsA(
        isA<Failure>().having(
          (error) => error.code,
          'code',
          FailureCode.unsupportedPlatform,
        ),
      ),
    );
  });

  test(
    'control: unavailable optional dependency does not block readiness',
    () async {
      final consumer = _Module('consumer', optionalRequires: {'http'});
      final registry = await KilnBootstrap.run(
        modules: [
          _Module(
            'provider',
            provides: {'http'},
            info: const SupportInfo.unsupported(
              SupportState.unavailable,
              message: 'offline',
            ),
          ),
          consumer,
        ],
      );
      expect(consumer.becameReady, isTrue);
      await registry.read<Lifecycle>().dispose();
    },
  );

  test('N4: details ignored but isRetryable participates in equality', () {
    const a = Failure(
      code: FailureCode.unexpected,
      message: 'boom',
      details: {'request_id': 'aaa'},
    );
    const b = Failure(
      code: FailureCode.unexpected,
      message: 'boom',
      details: {'request_id': 'bbb'},
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(a.copyWith(isRetryable: true)));
  });

  test('N6: missing snapshot rejects rollback and keeps recovery data', () {
    final project = Directory.systemTemp.createTempSync('kiln_review_');
    try {
      final original = File('${project.path}/existing.txt')
        ..writeAsStringSync('old');
      final tx = Transaction.begin(project)..writeText('existing.txt', 'new');
      tx.snapshots.backupFile('existing.txt').deleteSync();
      expect(tx.rollback, throwsA(isA<KilnException>()));
      expect(original.readAsStringSync(), 'new');
      expect(tx.journal.file.existsSync(), isTrue);
      expect(tx.snapshots.directory.existsSync(), isTrue);
    } finally {
      project.deleteSync(recursive: true);
    }
  });

  test('N7: concurrent registry disposal shares cleanup', () async {
    final registry = GetItRegistry();
    final entered = Completer<void>();
    final release = Completer<void>();
    var cleaned = false;
    registry.registerOwned<String>(
      'owned',
      dispose: () async {
        entered.complete();
        await release.future;
        cleaned = true;
      },
    );
    final first = registry.dispose();
    await entered.future;
    try {
      expect(registry.dispose(), same(first));
      expect(cleaned, isFalse);
      expect(registry.isRegistered<String>(), isTrue);
    } finally {
      release.complete();
      await first;
    }
    expect(cleaned, isTrue);
  });
}
