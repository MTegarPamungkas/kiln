import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'connectivity_config.dart';
import 'connectivity_gateway.dart';
import 'reachability_probe.dart';
import 'reconnect_trigger.dart';
import 'status_stabilizer.dart';

/// [NetworkMonitor] fed by a ConnectivityGateway.
final class DeviceNetworkMonitor implements NetworkMonitor {
  DeviceNetworkMonitor({
    required this.gateway,
    this.config = ConnectivityConfig.defaults,
    StatusStabilizer? stabilizer,
    this.reconnectTrigger,
    this.client,
  }) : _stabilizer =
           stabilizer ?? StatusStabilizer(window: config.debounceWindow);

  final ConnectivityGateway gateway;
  final ConnectivityConfig config;
  final StatusStabilizer _stabilizer;
  final ReconnectTrigger? reconnectTrigger;

  /// Optional transport used by [probeReachability]; without it the monitor
  /// only follows platform connectivity.
  final HttpClient? client;
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
    reconnectTrigger?.update(status);
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

  /// Probes the configured `probeUrl` through [client].
  ///
  /// Returns `true` when no probe URL or client is configured, because nothing
  /// disproves reachability. Failures and timeouts map to `false`.
  Future<bool> probeReachability() async {
    final url = config.probeUrl;
    final transport = client;
    if (url == null || url.isEmpty || transport == null) {
      return true;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return true;
    }
    return const ReachabilityProbe().probe(
      transport,
      uri,
      timeout: config.probeTimeout,
    );
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _stabilizer.dispose();
    await _changes.close();
  }
}
