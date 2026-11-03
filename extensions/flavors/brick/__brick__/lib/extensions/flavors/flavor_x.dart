import 'package:kiln_core/kiln_core.dart';

/// Selects a value for the running flavor.
extension FlavorX on AppFlavor {
  T valueFor<T>({
    required T development,
    required T staging,
    required T production,
    required T orElse,
  }) {
    if (this == AppFlavor.development) {
      return development;
    }
    if (this == AppFlavor.staging) {
      return staging;
    }
    if (this == AppFlavor.production) {
      return production;
    }
    return orElse;
  }
}
