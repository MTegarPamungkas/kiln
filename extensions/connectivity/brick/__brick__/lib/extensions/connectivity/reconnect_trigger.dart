import 'package:kiln_core/kiln_core.dart';

/// Runs a queued action when connectivity returns.
final class ReconnectTrigger {
  ReconnectTrigger({required this.onReconnect});

  final void Function() onReconnect;
  NetworkStatus? _last;

  void update(NetworkStatus status) {
    if (_last == NetworkStatus.offline && status == NetworkStatus.online) {
      onReconnect();
    }
    _last = status;
  }
}
