import 'package:kiln_core/kiln_core.dart';

import 'env_schema.dart';
import 'env_validator.dart';

/// Reports whether the active build-time environment can be used.
final class EnvSupport {
  const EnvSupport({
    required this.env,
    required this.schema,
    this.validator = const EnvValidator(),
  });

  final Env env;
  final EnvSchema schema;
  final EnvValidator validator;

  SupportInfo get info {
    final failure = validator.check(env, schema);
    if (failure != null) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: failure.message,
        details: <String, Object?>{
          'code': failure.code.value,
          ...failure.details,
        },
      );
    }
    return SupportInfo.supported(
      details: <String, Object?>{
        'keys': <String>[for (final key in schema.keys) key.name],
      },
    );
  }
}
