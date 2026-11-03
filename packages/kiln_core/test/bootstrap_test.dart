import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

final class _TrackedModule extends KilnModule {
  _TrackedModule(
    this.id, {
    this.provides = const <String>{},
    this.requires = const <String>{},
    this.readyAction,
    this.events,
  });

  @override
  final String id;
  @override
  final Set<String> provides;
  @override
  final Set<String> requires;
  final FutureOr<void> Function()? readyAction;
  final List<String>? events;

  @override
  void register(Registry registry) {
    events?.add('register:$id');
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

void main() {
  group('KilnBootstrap', () {
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
