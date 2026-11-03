import 'package:kiln_core/kiln_core.dart';

import 'notification_gateway.dart';

/// Asks the Permissions contract first and the plugin when it is absent.
final class NotificationPermissionFlow {
  const NotificationPermissionFlow({
    required this.gateway,
    this.permissions,
  });

  final NotificationGateway gateway;
  final Permissions? permissions;

  Future<bool> request() async {
    final contract = permissions;
    if (contract != null) {
      try {
        final status = await contract.ensure(PermissionKind.notifications);
        return status.isGranted;
      } on Failure {
        // The contract cannot answer on this platform; ask the plugin instead.
      }
    }
    return gateway.requestPermission();
  }
}
