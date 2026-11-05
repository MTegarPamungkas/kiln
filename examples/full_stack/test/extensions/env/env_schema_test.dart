import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/env/env_keys.dart';
import 'package:full_stack/extensions/env/env_schema.dart';

void main() {
  test('schema describes every active key', () {
    final schema = EnvSchema.defaults;

    expect(schema.keys, hasLength(4));
    expect(schema.contains(EnvKeys.apiBaseUrl), isTrue);
    expect(schema.spec(EnvKeys.apiBaseUrl)?.required, isTrue);
    expect(schema.spec(EnvKeys.apiBaseUrl)?.type, EnvValueType.uri);
    expect(schema.spec(EnvKeys.apiKey)?.secret, isTrue);
    expect(schema.spec(EnvKeys.enableDebugTools)?.type, EnvValueType.boolValue);
    expect(schema.spec('unknown'), isNull);
  });
}
