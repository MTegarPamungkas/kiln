import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{name}}/core/l10n/core_copy.dart';

import 'support/app_fixture.dart';
import 'support/test_core_copy.dart';

final class _RecordingLifecycle implements Lifecycle {
  int pauses = 0;
  int resumes = 0;

  LifecycleState _state = LifecycleState.created;
  final StreamController<LifecycleState> _changes =
      StreamController<LifecycleState>.broadcast(sync: true);

  @override
  LifecycleState get state => _state;

  @override
  Stream<LifecycleState> get changes => _changes.stream;

  @override
  Future<void> onReady() async {
    _state = LifecycleState.ready;
  }

  @override
  Future<void> onPause() async {
    pauses += 1;
    _state = LifecycleState.paused;
  }

  @override
  Future<void> onResume() async {
    resumes += 1;
    _state = LifecycleState.resumed;
  }

  @override
  Future<void> dispose() async {
    _state = LifecycleState.disposed;
    await _changes.close();
  }
}

void main() {
  testWidgets('forwards Flutter lifecycle to LifecycleController', (
    tester,
  ) async {
    final lifecycle = LifecycleController();
    final recorder = _RecordingLifecycle();
    lifecycle.attach(recorder);
    final registry = createTestRegistry(lifecycleController: lifecycle);
    registry.registerSingleton<CoreCopy>(const TestCoreCopy());

    await tester.pumpWidget(buildTestApp(registry));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(recorder.pauses, 1);
    expect(lifecycle.state, LifecycleState.paused);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(recorder.resumes, 1);
    expect(lifecycle.state, LifecycleState.resumed);

    await tester.pumpWidget(const SizedBox());
  });
}
