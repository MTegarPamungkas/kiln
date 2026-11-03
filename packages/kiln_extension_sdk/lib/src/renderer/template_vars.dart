import '../manifest/extension_manifest.dart';
import '../manifest/prompt_spec.dart';

/// Builds the variables Mason receives when rendering an extension brick.
Map<String, dynamic> buildTemplateVars({
  required AvailableExtension extension,
  Map<String, Object?> answers = const <String, Object?>{},
  Map<String, Object?> project = const <String, Object?>{},
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  final manifest = extension.manifest;
  final defaults = <String, Object?>{
    for (final prompt in manifest.prompts)
      if (prompt.defaultValue != null) prompt.name: prompt.defaultValue,
  };
  final validated = <String, Object?>{};
  for (final prompt in manifest.prompts) {
    final answer = answers.containsKey(prompt.name)
        ? answers[prompt.name]
        : defaults[prompt.name];
    final result = prompt.validate(answer);
    if (!result.isValid) {
      throw PromptAnswerException(prompt, result.error!);
    }
    validated[prompt.name] = result.value;
  }

  final id = manifest.id;
  return <String, dynamic>{
    'id': id,
    'id_snake': id,
    'id_camel': _camelCase(id),
    'id_pascal': _pascalCase(id),
    'id_param': id.replaceAll('_', '-'),
    'name': manifest.name,
    'description': manifest.description,
    'category': manifest.category,
    'version': manifest.version,
    if (project['name'] != null) 'app_name': project['name'],
    if (project['org'] != null) 'org': project['org'],
    if (project['state'] != null) 'state': project['state'],
    ...defaults,
    ...validated,
    ...answers,
    ...extra,
  };
}

/// A prompt answer that failed its declared type or range.
final class PromptAnswerException implements Exception {
  const PromptAnswerException(this.prompt, this.message);

  final PromptSpec prompt;
  final String message;

  @override
  String toString() => 'Invalid answer for "${prompt.name}": $message';
}

String _pascalCase(String value) {
  final parts = value
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty);
  return parts.map(_capitalize).join();
}

String _camelCase(String value) {
  final pascal = _pascalCase(value);
  if (pascal.isEmpty) {
    return pascal;
  }
  return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
}

String _capitalize(String value) =>
    '${value[0].toUpperCase()}${value.substring(1)}';
