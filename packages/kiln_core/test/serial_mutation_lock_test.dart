import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  test('serializes actions in arrival order', () async {
    final lock = SerialMutationLock();
    final events = <String>[];

    final results = await Future.wait([
      lock.runExclusive(() async {
        events.add('a-start');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        events.add('a-end');
        return 1;
      }),
      lock.runExclusive(() async {
        events.add('b-start');
        events.add('b-end');
        return 2;
      }),
    ]);

    expect(events, ['a-start', 'a-end', 'b-start', 'b-end']);
    expect(results, [1, 2]);
  });

  test('releases the lock when an action throws', () async {
    final lock = SerialMutationLock();

    await expectLater(
      lock.runExclusive<void>(() async => throw StateError('boom')),
      throwsA(isA<StateError>()),
    );

    expect(await lock.runExclusive(() async => 'ok'), 'ok');
  });
}
