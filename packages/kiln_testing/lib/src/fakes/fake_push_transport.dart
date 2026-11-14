import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import '../contracts/push_transport_contract.dart'
    show FakePushTransportEmitter;

/// [PushTransport] with an in-memory foreground stream the test drives
/// through [emit].
final class FakePushTransport
    implements PushTransport, FakePushTransportEmitter {
  FakePushTransport({this.tokenValue = 'fcm-fake-token'});

  String? tokenValue;
  Failure? failure;
  final List<String> calls = <String>[];
  bool disposed = false;

  final StreamController<PushEnvelope> _controller =
      StreamController<PushEnvelope>.broadcast();

  void emit(PushEnvelope envelope) {
    _controller.add(envelope);
  }

  @override
  Future<String?> token() async {
    calls.add('token');
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    return tokenValue;
  }

  @override
  Stream<PushEnvelope> get foreground => _controller.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    calls.add('dispose');
    await _controller.close();
  }
}
