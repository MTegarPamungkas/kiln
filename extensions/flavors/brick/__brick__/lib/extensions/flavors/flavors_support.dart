import 'package:kiln_core/kiln_core.dart';

/// Reports the flavor registered for this build.
final class FlavorsSupport {
  const FlavorsSupport({this.flavor});

  final AppFlavor? flavor;

  SupportInfo get info {
    final current = flavor;
    if (current == null) {
      return const SupportInfo.unsupported(
        SupportState.notConfigured,
        message: 'No AppFlavor is registered for this build.',
      );
    }
    return SupportInfo.supported(
      details: <String, Object?>{
        'flavor': current.name,
        'banner': !current.isProduction,
      },
    );
  }
}
