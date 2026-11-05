/// Biometric settings from the install prompts.
final class BiometricConfig {
  const BiometricConfig({
    this.reason = 'Unlock the app with biometrics',
    this.gracePeriod = const Duration(seconds: 30),
    this.biometricOnly = true,
  });

  static const defaults = BiometricConfig(
    reason: '{{{reason}}}',
    gracePeriod: Duration(seconds: {{grace_seconds}}),
    biometricOnly: {{biometric_only}},
  );

  final String reason;
  final Duration gracePeriod;
  final bool biometricOnly;
}
