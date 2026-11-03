import 'package:kiln_core/kiln_core.dart';

import 'share_gateway.dart';

/// [ShareService] backed by a ShareGateway.
final class DeviceShareService implements ShareService {
  const DeviceShareService({required this.gateway});

  final ShareGateway gateway;

  @override
  Future<ShareOutcome> share(ShareContent content, {ShareOrigin? origin}) {
    return gateway.share(content, origin: origin);
  }
}
