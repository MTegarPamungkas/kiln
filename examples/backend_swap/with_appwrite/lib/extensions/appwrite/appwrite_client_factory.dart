import 'package:appwrite/appwrite.dart';
import 'package:kiln_core/kiln_core.dart';

import 'appwrite_config.dart';

/// Builds the Appwrite client from [AppwriteConfig].
final class AppwriteClientFactory {
  const AppwriteClientFactory();

  /// Creates a configured client.
  ///
  /// Self-signed certificates are accepted only in the development flavor, so a
  /// local Appwrite instance can run behind HTTPS without weakening production.
  Client create({
    required AppwriteConfig config,
    AppFlavor flavor = AppFlavor.production,
  }) {
    config.validate();
    final client = Client(endPoint: config.endpoint)
      ..setProject(config.projectId);
    if (flavor == AppFlavor.development) {
      client.setSelfSigned(status: true);
    }
    return client;
  }
}
