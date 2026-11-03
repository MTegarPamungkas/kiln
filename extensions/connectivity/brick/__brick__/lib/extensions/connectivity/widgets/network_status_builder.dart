import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';

/// Rebuilds a widget according to the current network status.
class NetworkStatusBuilder extends StatelessWidget {
  const NetworkStatusBuilder({
    required this.monitor,
    required this.builder,
    super.key,
  });

  final NetworkMonitor monitor;
  final Widget Function(BuildContext context, NetworkStatus status) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkStatus>(
      stream: monitor.changes,
      initialData: monitor.status,
      builder: (context, snapshot) {
        return builder(context, snapshot.data ?? NetworkStatus.unknown);
      },
    );
  }
}
