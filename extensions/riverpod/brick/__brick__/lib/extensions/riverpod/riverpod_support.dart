import 'package:kiln_core/kiln_core.dart';

/// Reports the Riverpod state layer wiring.
final class RiverpodSupport {
  const RiverpodSupport();

  SupportInfo get info => const SupportInfo.supported(
    details: <String, Object?>{'state': 'riverpod', 'app_wrapper': true},
  );
}
