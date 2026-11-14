import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef PushTransportContractFactory = FutureOr<PushTransport> Function();

/// Behavior every [PushTransport] implementation must share.
void pushTransportContract({
  required PushTransportContractFactory create,
  String description = 'PushTransport',
}) {
  group('$description contract', () {
    test('token completes with null or a non-empty token', () async {
      final transport = await create();

      final token = await transport.token();

      if (token != null) {
        expect(token, isNotEmpty);
      }
    });

    test('foreground delivers envelopes emitted by the transport', () async {
      final transport = await create();
      // Real transports are driven by the platform; only fakes can be fed
      // from the test.
      final emitter = switch (transport) {
        FakePushTransportEmitter emitter => emitter,
        _ => null,
      };
      if (emitter == null) {
        return;
      }

      final delivered = Completer<PushEnvelope>();
      final subscription = transport.foreground.listen(delivered.complete);
      const envelope = PushEnvelope(
        title: 'Kiln',
        body: 'Hello from the transport',
        data: <String, Object?>{'route': '/inbox'},
      );
      emitter.emit(envelope);

      final received = await delivered.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw StateError('envelope not delivered'),
      );
      expect(received.title, 'Kiln');
      await subscription.cancel();
    });

    test('dispose completes without error', () async {
      final transport = await create();

      await transport.dispose();
    });
  });
}

/// Implemented by fakes that can push an [PushEnvelope] into their own
/// foreground stream during contract tests.
abstract interface class FakePushTransportEmitter {
  void emit(PushEnvelope envelope);
}
