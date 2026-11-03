import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'connectivity_config.dart';
import 'connectivity_gateway.dart';
import 'reconnect_trigger.dart';
import 'status_stabilizer.dart';

/// [NetworkMonitor] fed by a ConnectivityGateway.
final class DeviceNetworkMonitor implements NetworkMonitor {
  DeviceNetworkMonitor({
    required this.gateway,
    this.config = ConnectivityConfig.defaults,
    StatusStabilizer? stabilizer,
    this.reconnectTrigger,
  }) : _stabilizer =
           stabilizer ?? StatusStabilizer(window: config.debounceWindow);

  final ConnectivityGateway gateway;
  final ConnectivityConfig config;
  final StatusStabilizer _stabilizer;
  final ReconnectTrigger? reconnectTrigger;
  final StreamController<NetworkStatus> _changes =
      StreamController<NetworkStatus>.broadcast(sync: true);
  NetworkStatus _status = NetworkStatus.unknown;
  StreamSubscription<NetworkStatus>? _subscription;
  bool _started = false;

  @override
  NetworkStatus get status => _status;

  @override
  Stream<NetworkStatus> get changes => _changes.stream;

  Future<void> start() async {
    if (_started) {
      return;
    }
    final status = await gateway.check();
    final subscription = gateway.changes.listen((status) {
      _stabilizer.add(status, _emit);
    });
    _subscription = subscription;
    _started = true;
    _status = status;
    _changes.add(status);
  }

  void _emit(NetworkStatus status) {
    if (_status == status) {
      return;
    }
    _status = status;
    reconnectTrigger?.update(status);
    _changes.add(status);
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _stabilizer.dispose();
    await _changes.close();
  }
}
