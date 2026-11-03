import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

/// Shows a banner only when the device is confirmed offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.monitor,
    this.message = 'Anda sedang offline',
    super.key,
  });

  final NetworkMonitor monitor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkStatus>(
      stream: monitor.changes,
      initialData: monitor.status,
      builder: (context, snapshot) {
        if (snapshot.data != NetworkStatus.offline) {
          return const SizedBox.shrink();
        }
        final colors = Theme.of(context).colorScheme;
        return Material(
          color: colors.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 18,
                    color: colors.onErrorContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
