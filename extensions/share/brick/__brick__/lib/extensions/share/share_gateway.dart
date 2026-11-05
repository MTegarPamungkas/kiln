import 'package:kiln_core/kiln_core.dart';

/// Platform share access that can be faked in tests.
abstract interface class ShareGateway {
  Future<ShareOutcome> share(ShareContent content, {ShareOrigin? origin});
}
