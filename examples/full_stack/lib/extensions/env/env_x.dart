import 'package:kiln_core/kiln_core.dart';

/// Typed readers for [Env] values.
extension EnvX on Env {
  Uri? uri(String key) {
    final raw = read(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(raw);
    if (parsed == null || !parsed.hasScheme) {
      throw Failure(
        code: FailureCode.configurationInvalid,
        message: 'Environment $key bukan URI absolut.',
        kind: FailureKind.configuration,
        details: <String, Object?>{'key': key, 'value': raw},
      );
    }
    return parsed;
  }

  Duration? duration(String key) {
    final raw = read(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final value = int.tryParse(raw);
    if (value == null || value < 0) {
      throw Failure(
        code: FailureCode.configurationInvalid,
        message: 'Environment $key harus berupa jumlah detik.',
        kind: FailureKind.configuration,
        details: <String, Object?>{'key': key, 'value': raw},
      );
    }
    return Duration(seconds: value);
  }

  bool? boolValue(String key) {
    final raw = read(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    if (raw == 'true') {
      return true;
    }
    if (raw == 'false') {
      return false;
    }
    throw Failure(
      code: FailureCode.configurationInvalid,
      message: 'Environment $key harus true atau false.',
      kind: FailureKind.configuration,
      details: <String, Object?>{'key': key, 'value': raw},
    );
  }

  /// Reads a value that must match one of [allowed].
  T? enumValue<T>(String key, Map<String, T> allowed) {
    final raw = read(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final value = allowed[raw];
    if (value == null) {
      throw Failure(
        code: FailureCode.configurationInvalid,
        message: 'Environment $key tidak dikenal: $raw.',
        kind: FailureKind.configuration,
        details: <String, Object?>{
          'key': key,
          'value': raw,
          'allowed': allowed.keys.toList(growable: false),
        },
      );
    }
    return value;
  }
}
