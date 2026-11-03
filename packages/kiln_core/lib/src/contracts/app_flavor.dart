/// The build environment an application is currently running in.
///
/// Flavors are values, so an extension may define more than the three
/// standard ones without changing the contract.
final class AppFlavor {
  const AppFlavor(this.name, {this.isProduction = false});

  final String name;
  final bool isProduction;

  static const development = AppFlavor('development');
  static const staging = AppFlavor('staging');
  static const production = AppFlavor('production', isProduction: true);

  static const values = <AppFlavor>[development, staging, production];

  R when<R>({
    required R Function() development,
    required R Function() staging,
    required R Function() production,
    required R Function() orElse,
  }) {
    if (this == AppFlavor.development) {
      return development();
    }
    if (this == AppFlavor.staging) {
      return staging();
    }
    if (this == AppFlavor.production) {
      return production();
    }
    return orElse();
  }

  @override
  bool operator ==(Object other) =>
      other is AppFlavor &&
      other.name == name &&
      other.isProduction == isProduction;

  @override
  int get hashCode => Object.hash(name, isProduction);

  @override
  String toString() => name;
}
