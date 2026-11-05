import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// [NetworkMonitor] whose status is changed explicitly by a test.
final class FakeConnectivity implements NetworkMonitor {
  FakeConnectivity({NetworkStatus initial = NetworkStatus.unknown})
    : _status = initial;

  NetworkStatus _status;
  final StreamController<NetworkStatus> _changes =
      StreamController<NetworkStatus>.broadcast(sync: true);
  bool disposed = false;

  @override
  NetworkStatus get status => _status;

  @override
  Stream<NetworkStatus> get changes => _changes.stream;

  void setStatus(NetworkStatus status) {
    _status = status;
    _changes.add(status);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _changes.close();
  }
}
