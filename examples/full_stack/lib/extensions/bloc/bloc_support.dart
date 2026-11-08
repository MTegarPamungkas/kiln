import 'package:kiln_core/kiln_core.dart';

/// Reports the Bloc state layer wiring.
final class BlocSupport {
  const BlocSupport({required this.observerAttached});

  final bool observerAttached;

  SupportInfo get info => SupportInfo.supported(
    details: <String, Object?>{
      'state': 'bloc',
      'observer': observerAttached,
      'app_wrapper': true,
    },
  );
}
