import 'package:kiln_core/kiln_core.dart';

/// Reports the share-sheet capability.
final class ShareSupport {
  const ShareSupport();

  SupportInfo get info => const SupportInfo.supported(
    details: <String, Object?>{'share_sheet': true, 'files': true},
  );
}
