import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

final class _Probe {
  const _Probe(this.value);

  final int value;
}

final class _ProviderModule extends KilnModule {
  _ProviderModule(this.events);

  final List<String> events;

  @override
  String get id => 'provider';

  @override
  Set<String> get provides => const {'probe'};

  @override
  void register(Registry registry) {
    events.add('register:provider');
    registry.registerSingleton<_Probe>(const _Probe(42));
  }

  @override
  Future<void> ready(Registry registry) async {
    events.add('ready:provider');
  }
}

final class _ConsumerModule extends KilnModule {
  _ConsumerModule(this.events);

  final List<String> events;

  @override
  String get id => 'consumer';

  @override
  Set<String> get requires => const {'probe'};

  @override
  void register(Registry registry) {
    events.add('register:consumer');
    final probe = registry.read<_Probe>();
    events.add('value:${probe.value}');
  }

  @override
  Future<void> ready(Registry registry) async {
    events.add('ready:consumer');
  }
}

void main() {
  group('Registry and KilnModule', () {
    test('modules register services other modules can read', () async {
      final events = <String>[];
      final modules = <KilnModule>[
        _ConsumerModule(events),
        _ProviderModule(events),
      ];

      final registry = await KilnBootstrap.run(
        modules: modules,
        onModuleReady: (module) => events.add('callback:${module.id}'),
      );

      expect(events, [
        'register:provider',
        'ready:provider',
        'callback:provider',
        'register:consumer',
        'value:42',
        'ready:consumer',
        'callback:consumer',
      ]);
      expect(registry.read<_Probe>().value, 42);
    });

    test(
      'bootstrap installs the runtime services every module may use',
      () async {
        final registry = await KilnBootstrap.run(
          modules: <KilnModule>[_ProviderModule(<String>[])],
        );

        expect(registry.read<SlotRegistry>(), isA<SlotRegistry>());
        expect(
          registry.read<SessionController>().status,
          SessionStatus.unknown,
        );
        expect(registry.read<ConsentController>().hasAnyConsent, isFalse);
        expect(
          registry.read<LifecycleController>().state,
          LifecycleState.ready,
        );
        expect(registry.read<Lifecycle>(), isA<LifecycleController>());
        expect(registry.read<Clock>(), isA<SystemClock>());
      },
    );

    test('module ready can be asynchronous', () async {
      final module = _AsyncModule();
      final registry = await KilnBootstrap.run(modules: [module]);

      expect(module.readyCompleted, isTrue);
      expect(registry.read<String>(), 'ready');
    });
  });
}

final class _AsyncModule extends KilnModule {
  bool readyCompleted = false;

  @override
  String get id => 'async';

  @override
  void register(Registry registry) {}

  @override
  Future<void> ready(Registry registry) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    readyCompleted = true;
    registry.registerSingleton<String>('ready');
  }
}
