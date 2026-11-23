import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

final class _TrackedModule extends KilnModule {
  _TrackedModule(
    this.id, {
    this.provides = const <String>{},
    this.requires = const <String>{},
    this.platforms = const <String>{},
    this.readyAction,
    this.supportInfo,
    this.supportAction,
    this.events,
    this.requiredForStartup = false,
  });

  @override
  final String id;
  @override
  final Set<String> provides;
  @override
  final Set<String> requires;
  @override
  final Set<String> platforms;
  final FutureOr<void> Function()? readyAction;
  final SupportInfo? supportInfo;
  final FutureOr<SupportInfo> Function()? supportAction;
  final List<String>? events;
  @override
  final bool requiredForStartup;

  @override
  void register(Registry registry) {
    events?.add('register:$id');
  }

  @override
  FutureOr<SupportInfo> support(Registry registry) {
    final action = supportAction;
    if (action != null) {
      return action();
    }
    return supportInfo ?? const SupportInfo.supported();
  }

  @override
  Future<void> ready(Registry registry) async {
    events?.add('ready:$id');
    final action = readyAction;
    if (action != null) {
      await action();
    }
  }

  @override
  Future<void> dispose() async {
    events?.add('dispose:$id');
  }
}

final class _FailingRegisterModule extends KilnModule {
  _FailingRegisterModule({required this.events});

  final List<String> events;

  @override
  String get id => 'broken-register';

  @override
  void register(Registry registry) => throw StateError('register failed');

  @override
  void dispose() {
    events.add('dispose:$id');
  }
}

final class _GateConsumerModule extends KilnModule {
  final List<Gate> gates = <Gate>[];

  @override
  String get id => 'gate-consumer';

  @override
  void register(Registry registry) => gates.add(registry.read<Gate>());

  @override
  SupportInfo support(Registry registry) {
    gates.add(registry.read<Gate>());
    return const SupportInfo.supported();
  }

  @override
  void ready(Registry registry) => gates.add(registry.read<Gate>());
}

void main() {
  group('KilnBootstrap', () {
    test('required modules cannot silently degrade', () async {
      final events = <String>[];
      await expectLater(
        KilnBootstrap.run(
          modules: [
            _TrackedModule(
              'env',
              requiredForStartup: true,
              events: events,
              supportInfo: SupportInfo.unsupported(
                SupportState.unavailable,
                message: 'Unavailable',
              ),
            ),
          ],
        ),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.unavailable,
          ),
        ),
      );
      expect(events, ['register:env', 'dispose:env']);
    });

    test(
      'a required module with invalid config fails with its typed reason',
      () async {
        await expectLater(
          KilnBootstrap.run(
            modules: [
              _TrackedModule(
                'env',
                requiredForStartup: true,
                supportInfo: const SupportInfo.unsupported(
                  SupportState.notConfigured,
                  message: 'Missing API key',
                ),
              ),
            ],
          ),
          throwsA(
            isA<Failure>()
                .having(
                  (failure) => failure.code,
                  'code',
                  FailureCode.configurationMissing,
                )
                .having(
                  (failure) => failure.kind,
                  'kind',
                  FailureKind.configuration,
                ),
          ),
        );
      },
    );

    test('unavailable capabilities prevent dependent readiness', () async {
      final events = <String>[];
      final ready = <String>[];
      final registry = await KilnBootstrap.run(
        modules: [
          _TrackedModule(
            'backend',
            provides: {'database'},
            events: events,
            supportInfo: SupportInfo.unsupported(
              SupportState.unavailable,
              message: 'Unavailable',
            ),
          ),
          _TrackedModule(
            'consumer',
            requires: {'database'},
            provides: {'feature'},
            events: events,
          ),
          _TrackedModule('independent', events: events),
        ],
        onModuleReady: (module) => ready.add(module.id),
      );
      addTearDown(registry.read<Lifecycle>().dispose);
      expect(events, isNot(contains('ready:consumer')));
      expect(
        registry.read<SupportRegistry>()['consumer']!.isSupported,
        isFalse,
      );
      expect(ready, ['independent']);
    });

    test(
      'platform-filtered capabilities disable transitive dependents',
      () async {
        final events = <String>[];
        final registry = await KilnBootstrap.run(
          platform: 'android',
          modules: [
            _TrackedModule('web', platforms: {'web'}, provides: {'database'}),
            _TrackedModule(
              'consumer',
              requires: {'database'},
              provides: {'feature'},
              events: events,
            ),
            _TrackedModule('transitive', requires: {'feature'}, events: events),
            _TrackedModule('independent', events: events),
          ],
        );
        addTearDown(registry.read<Lifecycle>().dispose);
        expect(events, isNot(contains('register:consumer')));
        expect(events, isNot(contains('register:transitive')));
        expect(events, contains('ready:independent'));
        final support = registry.read<SupportRegistry>();
        expect(support['web']?.state, SupportState.unsupportedPlatform);
        expect(support['consumer']?.state, SupportState.unavailable);
        expect(support['transitive']?.state, SupportState.unavailable);
      },
    );

    test('apps can require a backend capability explicitly', () async {
      await expectLater(
        KilnBootstrap.run(
          modules: [
            _TrackedModule(
              'backend',
              provides: {'database'},
              supportInfo: SupportInfo.unsupported(
                SupportState.unavailable,
                message: 'Unavailable',
              ),
            ),
          ],
          requiredCapabilities: {'database'},
        ),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.unavailable,
          ),
        ),
      );
    });

    test('provides the same Gate throughout module initialization', () async {
      final module = _GateConsumerModule();
      final registry = await KilnBootstrap.run(modules: [module]);
      addTearDown(registry.read<Lifecycle>().dispose);
      final gate = registry.read<Gate>();

      expect(gate.registry, same(registry));
      expect(module.gates, hasLength(3));
      for (final observed in module.gates) {
        expect(observed, same(gate));
      }
      expect(gate.session, same(registry.read<SessionController>()));
      final result = await gate.signOut();
      expect(result.failureOrNull?.code, FailureCode.configurationMissing);
    });

    test('keeps Gate and its services isolated between bootstraps', () async {
      final first = await KilnBootstrap.run(modules: []);
      final second = await KilnBootstrap.run(modules: []);
      addTearDown(first.read<Lifecycle>().dispose);
      addTearDown(second.read<Lifecycle>().dispose);

      expect(first.read<Gate>(), isNot(same(second.read<Gate>())));
      expect(first.read<Gate>().registry, same(first));
      expect(second.read<Gate>().registry, same(second));
      expect(
        first.read<Gate>().session,
        isNot(same(second.read<Gate>().session)),
      );
      expect(Gate(first).session, same(first.read<Gate>().session));
    });

    test('skips modules that do not support the current platform', () async {
      final events = <String>[];
      await KilnBootstrap.run(
        modules: [
          _TrackedModule('web-only', platforms: const {'web'}, events: events),
          _TrackedModule(
            'android',
            platforms: const {'android'},
            events: events,
          ),
        ],
        platform: 'android',
      );

      expect(events, ['register:android', 'ready:android']);
      final support = await KilnBootstrap.run(
        modules: [
          _TrackedModule('web-only', platforms: const {'web'}),
          _TrackedModule('android', platforms: const {'android'}),
        ],
        platform: 'android',
      );
      expect(
        support.read<SupportRegistry>()['web-only']?.state,
        SupportState.unsupportedPlatform,
      );
    });

    test('skips ready and records device support info', () async {
      final events = <String>[];
      final registry = await KilnBootstrap.run(
        modules: [
          _TrackedModule(
            'sensor',
            supportInfo: const SupportInfo.unsupported(
              SupportState.unsupportedDevice,
              message: 'No sensor on this device.',
            ),
            events: events,
          ),
        ],
      );

      expect(events, ['register:sensor']);
      final info = registry.read<SupportRegistry>()['sensor'];
      expect(info?.state, SupportState.unsupportedDevice);
      expect(info?.message, 'No sensor on this device.');
      expect(info?.isDeviceUnsupported, isTrue);
    });

    test('records a failed support probe and keeps bootstrapping', () async {
      final events = <String>[];
      final registry = await KilnBootstrap.run(
        modules: [
          _TrackedModule(
            'probe',
            supportAction: () => throw StateError('probe failed'),
            events: events,
          ),
        ],
      );

      expect(events, ['register:probe']);
      final info = registry.read<SupportRegistry>()['probe'];
      expect(info?.state, SupportState.unavailable);
      expect(info?.message, contains('probe failed'));
    });

    test('records supported modules before calling ready', () async {
      final events = <String>[];
      final registry = await KilnBootstrap.run(
        modules: [_TrackedModule('ok', events: events)],
      );

      expect(events, ['register:ok', 'ready:ok']);
      expect(registry.read<SupportRegistry>()['ok']?.isSupported, isTrue);
    });

    test('runs modules in dependency order', () async {
      final events = <String>[];
      final registry = await KilnBootstrap.run(
        modules: [
          _TrackedModule('ui', requires: const {'http'}, events: events),
          _TrackedModule('http', provides: const {'http'}, events: events),
        ],
        onModuleReady: (module) => events.add('done:${module.id}'),
      );

      expect(events, [
        'register:http',
        'ready:http',
        'done:http',
        'register:ui',
        'ready:ui',
        'done:ui',
      ]);
      expect(registry.read<SessionController>(), isA<SessionController>());
    });

    test('honors the ready timeout and disposes registered modules', () async {
      final events = <String>[];
      final never = Completer<void>();

      await expectLater(
        KilnBootstrap.run(
          modules: [
            _TrackedModule(
              'slow',
              events: events,
              readyAction: () => never.future,
            ),
          ],
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(events, ['register:slow', 'ready:slow', 'dispose:slow']);
    });

    test('calls the error handler and still rethrows', () async {
      final errors = <Object>[];
      final events = <String>[];

      await expectLater(
        KilnBootstrap.run(
          modules: [
            _TrackedModule(
              'broken',
              events: events,
              readyAction: () => throw StateError('broken module'),
            ),
          ],
          onError: (error, stackTrace) => errors.add(error),
        ),
        throwsA(isA<StateError>()),
      );

      expect(errors, hasLength(1));
      expect(errors.single, isA<StateError>());
      expect(events, ['register:broken', 'ready:broken', 'dispose:broken']);
    });

    test('propagates graph errors before registering anything', () async {
      final events = <String>[];

      await expectLater(
        KilnBootstrap.run(
          modules: [
            _TrackedModule(
              'consumer',
              requires: const {'missing'},
              events: events,
            ),
          ],
        ),
        throwsA(isA<ModuleGraphException>()),
      );

      expect(events, isEmpty);
    });

    test('lifecycle shutdown disposes modules in reverse order', () async {
      final events = <String>[];
      final registry = await KilnBootstrap.run(
        modules: [
          _TrackedModule('first', provides: const {'a'}, events: events),
          _TrackedModule('second', requires: const {'a'}, events: events),
        ],
      );

      await registry.read<LifecycleController>().dispose();

      expect(events, [
        'register:first',
        'ready:first',
        'register:second',
        'ready:second',
        'dispose:second',
        'dispose:first',
      ]);
    });

    test('lifecycle shutdown is idempotent', () async {
      final events = <String>[];
      final registry = await KilnBootstrap.run(
        modules: [_TrackedModule('once', events: events)],
      );
      final lifecycle = registry.read<LifecycleController>();

      await Future.wait([lifecycle.dispose(), lifecycle.dispose()]);
      await lifecycle.dispose();

      expect(events.where((event) => event == 'dispose:once'), hasLength(1));
      expect(() => lifecycle.addDisposeCallback(() {}), throwsStateError);
    });

    test('lifecycle shutdown disposes registry-owned services', () async {
      final registry = await KilnBootstrap.run(
        modules: [const _OwnedResourceModule()],
      );
      final owned = registry.read<_OwnedResource>();
      final lifecycle = registry.read<LifecycleController>();

      await lifecycle.dispose();

      expect(owned.disposed, isTrue);
      expect(registry.isRegistered<_OwnedResource>(), isFalse);
    });

    test('a module that fails to register is still disposed', () async {
      final events = <String>[];
      final registry = KilnBootstrap.run(
        modules: [
          _TrackedModule('ok', provides: const {'a'}, events: events),
          _FailingRegisterModule(events: events),
        ],
      );

      await expectLater(registry, throwsStateError);
      expect(events, containsAll(<String>['register:ok', 'dispose:ok']));
      expect(events, contains('dispose:broken-register'));
    });

    test('uses the injected clock', () async {
      final clock = FixedClock(DateTime.utc(2026, 11, 1));
      final registry = await KilnBootstrap.run(
        modules: <KilnModule>[],
        clock: clock,
      );

      expect(registry.read<Clock>(), same(clock));
    });
  });
}

final class _OwnedResource implements Disposable {
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

final class _OwnedResourceModule extends KilnModule {
  const _OwnedResourceModule();

  @override
  String get id => 'owned';

  @override
  void register(Registry registry) {
    registry.registerOwned<_OwnedResource>(_OwnedResource());
  }
}
