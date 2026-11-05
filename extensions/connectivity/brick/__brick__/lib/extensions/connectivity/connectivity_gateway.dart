import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kiln_core/kiln_core.dart';

/// Platform connectivity access that can be faked in tests.
abstract interface class ConnectivityGateway {
  Future<NetworkStatus> check();

  Stream<NetworkStatus> get changes;
}

/// Gateway backed by connectivity_plus.
final class ConnectivityPlusGateway implements ConnectivityGateway {
  ConnectivityPlusGateway({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  NetworkStatus _map(List<ConnectivityResult> results) {
    if (results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }

  @override
  Future<NetworkStatus> check() async {
    return _map(await _connectivity.checkConnectivity());
  }

  @override
  Stream<NetworkStatus> get changes =>
      _connectivity.onConnectivityChanged.map(_map);
}
