/// Current reachability of the network.
enum NetworkStatus { unknown, online, offline }

/// Reports device connectivity and changes to it.
abstract interface class NetworkMonitor {
  NetworkStatus get status;

  Stream<NetworkStatus> get changes;

  Future<void> dispose();
}
