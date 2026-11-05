/// Typed description of one environment key.
enum EnvValueType { string, uri, boolValue, duration, enumValue }

/// One key declared by the generated environment schema.
final class EnvKeySpec {
  const EnvKeySpec({
    required this.name,
    required this.type,
    this.required = false,
    this.secret = false,
    this.allowedValues = const <String>[],
  });

  final String name;
  final EnvValueType type;
  final bool required;
  final bool secret;
  final List<String> allowedValues;
}

/// The environment keys active for this application.
final class EnvSchema {
  const EnvSchema({required this.keys});

  static const allKeys = <EnvKeySpec>[
    EnvKeySpec(
      name: 'api_base_url',
      type: EnvValueType.uri,
      required: true,
    ),
    EnvKeySpec(
      name: 'api_key',
      type: EnvValueType.string,
      secret: true,
    ),
    EnvKeySpec(name: 'feature_flags', type: EnvValueType.string),
    EnvKeySpec(name: 'enable_debug_tools', type: EnvValueType.boolValue),
  ];

  static const activeNames = <String>{
    'api_base_url',
    'api_key',
    'feature_flags',
    'enable_debug_tools',
    
  };

  static final defaults = EnvSchema(
    keys: allKeys
        .where((key) => activeNames.contains(key.name))
        .toList(growable: false),
  );

  final List<EnvKeySpec> keys;

  bool contains(String name) => keys.any((key) => key.name == name);

  EnvKeySpec? spec(String name) {
    for (final key in keys) {
      if (key.name == name) {
        return key;
      }
    }
    return null;
  }
}
