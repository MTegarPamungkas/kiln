import 'package:kiln_core/kiln_core.dart';

import 'device_network_monitor.dart';

/// Gate verbs for the connectivity capability.
///
/// `gate.network` already exposes the device `status` and the `changes` stream.
/// This adds on-demand server reachability using the probe URL configured at
/// install time. The SDK reports the result; the app decides what to show.
extension GateConnectivityX on Gate {
  DeviceNetworkMonitor get deviceNetwork => use<DeviceNetworkMonitor>();

  /// Probes `probeUrl` through the HTTP client. `Ok(true)` when no probe is
  /// configured or the server responds successfully; a failure or timeout is
  /// `Ok(false)`.
  Future<Result<bool>> networkReachable() =>
      call(deviceNetwork.probeReachability);
}
