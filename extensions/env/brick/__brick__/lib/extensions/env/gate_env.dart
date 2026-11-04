import 'package:kiln_core/kiln_core.dart';

import 'env_describe.dart';
import 'env_schema.dart';
import 'env_validator.dart';
import 'env_x.dart';

/// Gate verbs for the environment capability.
///
/// Augments the kiln_core [Gate] facade so the application reads typed
/// build-time values and validates configuration with a single call that
/// returns a [Result]. The application still owns the UI; the SDK only
/// reports values, success, failure, and information.
extension GateEnvX on Gate {
  EnvSchema get envSchema => use<EnvSchema>();

  EnvValidator get envValidator => use<EnvValidator>();

  /// Reads [key] as an absolute [Uri]; `Ok(null)` means the key is unset.
  Future<Result<Uri?>> envUri(String key) => call(() => env.uri(key));

  /// Reads [key] as a whole number of seconds; `Ok(null)` means unset.
  Future<Result<Duration?>> envDuration(String key) =>
      call(() => env.duration(key));

  /// Reads [key] as a boolean; `Ok(null)` means unset.
  Future<Result<bool?>> envBool(String key) => call(() => env.boolValue(key));

  /// Reads [key] against [allowed]; `Ok(null)` means unset.
  Future<Result<T?>> envEnum<T>(String key, Map<String, T> allowed) =>
      call(() => env.enumValue(key, allowed));

  /// Reports every missing required key as one [Err], or [Ok] when complete.
  Future<Result<void>> validateEnv() =>
      call<void>(() => envValidator.validate(env, envSchema));

  /// Returns a log-safe summary with secret values replaced by [replacement].
  Map<String, String> describeEnv({String replacement = '[redacted]'}) =>
      EnvDescribe(replacement: replacement).summarize(env, envSchema);
}
