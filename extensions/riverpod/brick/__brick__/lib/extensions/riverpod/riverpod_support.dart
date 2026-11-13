import 'package:kiln_core/kiln_core.dart';

/// Reports the Riverpod state layer wiring.
final class RiverpodSupport {
  const RiverpodSupport({this.observerAttached = false});

  final bool observerAttached;

  SupportInfo get info => SupportInfo.supported(
    details: <String, Object?>{
      'state': 'riverpod',
      'app_wrapper': true,
      'observer': observerAttached,
    },
  );
}
