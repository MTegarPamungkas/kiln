import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

final class _Recorder implements Lifecycle {
  final List<String> calls = <String>[];
  LifecycleState _state = LifecycleState.created;

  @override
  LifecycleState get state => _state;

  @override
  Stream<LifecycleState> get changes => const Stream<LifecycleState>.empty();

  @override
  Future<void> onReady() async {
    calls.add('ready');
    _state = LifecycleState.ready;
  }

  @override
  Future<void> onPause() async {
    calls.add('pause');
    _state = LifecycleState.paused;
  }

  @override
  Future<void> onResume() async {
    calls.add('resume');
    _state = LifecycleState.resumed;
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    _state = LifecycleState.disposed;
  }
}

void main() {
  group('LifecycleController', () {
    test('forwards callbacks and emits state transitions', () async {
      final controller = LifecycleController();
      final listener = _Recorder();
      final emissions = <LifecycleState>[];
      final subscription = controller.changes.listen(emissions.add);

      controller.attach(listener);

      await controller.onReady();
      await controller.onPause();
      await controller.onResume();
      await controller.dispose();

      expect(listener.calls, ['ready', 'pause', 'resume', 'dispose']);
      expect(controller.state, LifecycleState.disposed);
      expect(emissions, [
        LifecycleState.ready,
        LifecycleState.paused,
        LifecycleState.resumed,
        LifecycleState.disposed,
      ]);
      await subscription.cancel();
    });

    test('attaching the same listener twice keeps one registration', () async {
      final controller = LifecycleController();
      final listener = _Recorder();

      controller.attach(listener);
      controller.attach(listener);
      await controller.onReady();

      expect(controller.listeners, hasLength(1));
      expect(listener.calls, ['ready']);
    });

    test('detached listeners stop receiving callbacks', () async {
      final controller = LifecycleController();
      final listener = _Recorder();

      controller.attach(listener);
      controller.detach(listener);
      await controller.onReady();

      expect(listener.calls, isEmpty);
      expect(controller.state, LifecycleState.ready);
    });

    test('does not emit a state that is already current', () async {
      final controller = LifecycleController();
      final emissions = <LifecycleState>[];
      final subscription = controller.changes.listen(emissions.add);

      await controller.onReady();
      await controller.onReady();

      expect(emissions, [LifecycleState.ready]);
      await subscription.cancel();
      await controller.dispose();
    });

    test('a throwing listener does not stop others or the transition', () async {
      final controller = LifecycleController();
      final healthy = _Recorder();
      controller
        ..attach(_Scripted(onPauseAction: () => throw StateError('boom')))
        ..attach(healthy);

      await expectLater(controller.onPause(), throwsStateError);

      expect(healthy.calls, ['pause']);
      expect(controller.state, LifecycleState.paused);
      await controller.dispose();
    });

    test('a hung listener times out without blocking the others', () async {
      final controller = LifecycleController(
        listenerTimeout: const Duration(milliseconds: 20),
      );
      final hang = Completer<void>();
      final healthy = _Recorder();
      controller
        ..attach(_Scripted(onPauseAction: () => hang.future))
        ..attach(healthy);

      await expectLater(
        controller.onPause().timeout(const Duration(seconds: 2)),
        throwsA(isA<TimeoutException>()),
      );

      expect(healthy.calls, ['pause']);
      expect(controller.state, LifecycleState.paused);
      hang.complete();
      await controller.dispose();
    });

    test('listeners run concurrently', () async {
      final controller = LifecycleController();
      final first = Completer<void>();
      var secondStarted = false;
      controller
        ..attach(_Scripted(onPauseAction: () => first.future))
        ..attach(
          _Scripted(
            onPauseAction: () async {
              secondStarted = true;
            },
          ),
        );

      final pausing = controller.onPause();
      await Future<void>.delayed(Duration.zero);
      expect(secondStarted, isTrue);
      first.complete();
      await pausing;
      await controller.dispose();
    });
  });
}

final class _Scripted implements Lifecycle {
  _Scripted({required this.onPauseAction});

  final Future<void> Function() onPauseAction;

  @override
  LifecycleState get state => LifecycleState.created;

  @override
  Stream<LifecycleState> get changes => const Stream<LifecycleState>.empty();

  @override
  Future<void> onReady() async {}

  @override
  Future<void> onPause() => onPauseAction();

  @override
  Future<void> onResume() async {}

  @override
  Future<void> dispose() async {}
}
