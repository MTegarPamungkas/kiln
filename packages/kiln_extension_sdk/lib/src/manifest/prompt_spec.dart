import '../kiln_exception.dart';

/// Kind of answer a prompt accepts.
enum PromptType { string, url, intValue, boolValue, enumValue, secret, multi }

/// Result of validating and normalizing one prompt answer.
final class PromptValidation {
  const PromptValidation.valid(this.value) : error = null;

  const PromptValidation.invalid(this.error) : value = null;

  final Object? value;
  final String? error;

  bool get isValid => error == null;
}

/// One typed question an extension asks before rendering.
final class PromptSpec {
  const PromptSpec({
    required this.name,
    required this.type,
    this.label,
    this.description,
    this.defaultValue,
    this.required = false,
    this.secret = false,
    this.multiple = false,
    this.options = const <String>[],
    this.min,
    this.max,
  });

  final String name;
  final PromptType type;
  final String? label;
  final String? description;
  final Object? defaultValue;
  final bool required;
  final bool secret;
  final bool multiple;
  final List<String> options;
  final int? min;
  final int? max;

  bool get isMulti => multiple || type == PromptType.multi;

  PromptValidation validate(Object? input) {
    if (input == null) {
      if (required && defaultValue == null) {
        return PromptValidation.invalid('$name is required');
      }
      return PromptValidation.valid(defaultValue);
    }

    switch (type) {
      case PromptType.string:
      case PromptType.secret:
        final value = '$input';
        if (required && value.trim().isEmpty) {
          return PromptValidation.invalid('$name must not be empty');
        }
        return PromptValidation.valid(value);
      case PromptType.url:
        final value = '$input';
        final uri = Uri.tryParse(value);
        if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
          return PromptValidation.invalid('$name must be an absolute URL');
        }
        if (uri.scheme != 'http' && uri.scheme != 'https') {
          return PromptValidation.invalid('$name must use http or https');
        }
        return PromptValidation.valid(value);
      case PromptType.intValue:
        final value = input is int ? input : int.tryParse('$input');
        if (value == null) {
          return PromptValidation.invalid('$name must be an integer');
        }
        if (min != null && value < min!) {
          return PromptValidation.invalid('$name must be at least $min');
        }
        if (max != null && value > max!) {
          return PromptValidation.invalid('$name must be at most $max');
        }
        return PromptValidation.valid(value);
      case PromptType.boolValue:
        if (input is bool) {
          return PromptValidation.valid(input);
        }
        if (input == 'true' || input == 'false') {
          return PromptValidation.valid(input == 'true');
        }
        return PromptValidation.invalid('$name must be true or false');
      case PromptType.enumValue:
        final value = '$input';
        if (!options.contains(value)) {
          return PromptValidation.invalid(
            '$name must be one of ${options.join(', ')}',
          );
        }
        return PromptValidation.valid(value);
      case PromptType.multi:
        final values = input is Iterable
            ? input.map((value) => '$value')
            : ['$input'];
        final unknown = values.where((value) => !options.contains(value));
        if (unknown.isNotEmpty) {
          return PromptValidation.invalid(
            '$name contains unsupported values: ${unknown.join(', ')}',
          );
        }
        if (required && values.isEmpty) {
          return PromptValidation.invalid(
            '$name must select at least one value',
          );
        }
        return PromptValidation.valid(values.toList());
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'type': _typeName,
    if (label != null) 'label': label,
    if (description != null) 'description': description,
    if (defaultValue != null) 'default': defaultValue,
    if (required) 'required': required,
    if (secret) 'secret': secret,
    if (multiple) 'multiple': multiple,
    if (options.isNotEmpty) 'options': options,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
  };

  String get _typeName => switch (type) {
    PromptType.intValue => 'int',
    PromptType.boolValue => 'bool',
    PromptType.enumValue => 'enum',
    PromptType.multi => 'multi',
    _ => type.name,
  };

  static PromptSpec fromMap(Map<String, Object?> map) {
    final name = '${map['name'] ?? ''}';
    if (name.isEmpty) {
      throw const KilnException('Prompt is missing a name');
    }
    return PromptSpec(
      name: name,
      type: _parseType(map['type']),
      label: map['label'] as String?,
      description: map['description'] as String?,
      defaultValue: map['default'],
      required: map['required'] == true,
      secret: map['secret'] == true,
      multiple: map['multiple'] == true,
      options: _stringList(map['options']),
      min: _asInt(map['min']),
      max: _asInt(map['max']),
    );
  }

  static PromptType _parseType(Object? value) {
    return switch ('$value') {
      'string' => PromptType.string,
      'url' => PromptType.url,
      'int' => PromptType.intValue,
      'bool' => PromptType.boolValue,
      'enum' => PromptType.enumValue,
      'secret' => PromptType.secret,
      'multi' => PromptType.multi,
      _ => throw KilnException('Unsupported prompt type: $value'),
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const <String>[];
    }
    return value.map((entry) => '$entry').toList(growable: false);
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    return value == null ? null : int.tryParse('$value');
  }
}
