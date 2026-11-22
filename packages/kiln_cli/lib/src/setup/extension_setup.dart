import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

import '../infra/prompter.dart';
import 'appwrite_setup.dart';

/// Manifest-driven local configuration. Runtime support is checked by the app.
final class ExtensionSetup {
  const ExtensionSetup(this.manifest);

  final ExtensionManifest manifest;

  bool isSecret(PromptSpec prompt) =>
      prompt.secret || prompt.type == PromptType.secret;

  Object? parse(PromptSpec prompt, String raw) {
    if (prompt.isMulti) {
      return raw
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
    }
    return switch (prompt.type) {
      PromptType.intValue => int.tryParse(raw.trim()) ?? raw,
      PromptType.boolValue => switch (raw.trim().toLowerCase()) {
        'true' || 'yes' || 'y' || '1' => true,
        'false' || 'no' || 'n' || '0' => false,
        _ => raw,
      },
      PromptType.url when raw.trim().isEmpty && !prompt.required => null,
      PromptType.url => raw.trim(),
      _ => raw,
    };
  }

  String? _issue(PromptSpec prompt, Object? value) {
    if (value != null) {
      final typed = prompt.isMulti
          ? value is List && value.every((item) => item is String)
          : switch (prompt.type) {
              PromptType.intValue => value is int,
              PromptType.boolValue => value is bool,
              _ => value is String,
            };
      if (!typed) return '${prompt.name} has an invalid value type.';
    }
    final validation = prompt.validate(value);
    // Never echo a candidate value, including secret values or list members.
    if (!validation.isValid) {
      return '${prompt.name} does not match its declared type, allowed values, or range.';
    }
    if (prompt.required &&
        (validation.value == null ||
            validation.value is String &&
                (validation.value! as String).trim().isEmpty ||
            validation.value is List && (validation.value! as List).isEmpty)) {
      return '${prompt.name} is required.';
    }
    return null;
  }

  Map<String, String> issues(Map<String, Object?> answers, {Directory? root}) {
    final result = <String, String>{};
    for (final prompt in manifest.prompts) {
      final value = answers.containsKey(prompt.name)
          ? answers[prompt.name]
          : prompt.defaultValue;
      final issue = _issue(prompt, value);
      if (issue != null) result[prompt.name] = issue;
    }
    if (manifest.id == 'appwrite') {
      result.addAll(
        AppwriteSetup({...AppwriteSetup.defaults, ...answers}).issues,
      );
    }
    if (manifest.id == 'l10n') {
      final locales = answers['locales'] ?? _default('locales');
      final fallback =
          answers['fallback_locale'] ?? _default('fallback_locale');
      if (locales is List && (locales.isEmpty || !locales.contains(fallback))) {
        result['locales'] =
            'Supported locales must include the fallback locale.';
      }
    }
    final flavors = answers['flavors'] ?? _default('flavors');
    if (manifest.id == 'flavors' && flavors is List && flavors.isEmpty) {
      result['flavors'] = 'Select at least one application flavor.';
    }
    if (manifest.id == 'theme') {
      final color = answers['seed_color'] ?? _default('seed_color');
      if (color is String && !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color)) {
        result['seed_color'] = 'Use a seed color in #RRGGBB format.';
      }
    }
    if (manifest.id == 'deep_link') {
      final scheme = answers['scheme'] ?? _default('scheme');
      if (scheme is String &&
          !RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*$').hasMatch(scheme)) {
        result['scheme'] = 'Use a URI scheme beginning with a letter, followed by letters, digits, +, -, or period.';
      }
    }
    if (manifest.id == 'supabase') {
      final schema = answers['schema'] ?? _default('schema');
      if (schema is String && !RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(schema)) {
        result['schema'] = 'Use a lowercase PostgREST schema identifier.';
      }
    }
    if (manifest.id == 'remote_config') {
      final endpoint = answers['endpoint'];
      if (endpoint is String &&
          endpoint.trim().isNotEmpty &&
          !_httpUrl(endpoint)) {
        result['endpoint'] = 'Use an absolute HTTP(S) remote config endpoint or leave it empty for defaults only.';
      }
    }
    if (manifest.id == 'firebase' &&
        root != null &&
        (answers['options_source'] ?? _default('options_source')) ==
            'generated') {
      final path =
          answers['firebase_options_path'] ?? _default('firebase_options_path');
      if (path is String) {
        final target = p.normalize(p.join(root.path, path));
        if (p.isAbsolute(path) ||
            !p.isWithin(root.absolute.path, p.absolute(target)) ||
            !File(target).existsSync()) {
          result['firebase_options_path'] = 'The generated Firebase options file is missing or outside the project. Complete FlutterFire configuration first.';
        }
      }
    }
    return result;
  }

  Object? _default(String name) => manifest.prompts
      .where((prompt) => prompt.name == name)
      .firstOrNull
      ?.defaultValue;

  bool _httpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.host.isNotEmpty &&
        const {'http', 'https'}.contains(uri.scheme);
  }

  List<String> get nextSteps => <String>{
    ...manifest.manualSteps.map((step) => step.description),
    if (manifest.id == 'appwrite') ...AppwriteSetup.nextSteps,
    if (manifest.id == 'analytics')
      'An empty API key keeps analytics disabled.',
    if (manifest.id == 'crash_report')
      'An empty DSN keeps crash reporting disabled.',
    if (manifest.prompts.any(isSecret))
      'Use env:VARIABLE_NAME for a client value supplied with Flutter --dart-define or --dart-define-from-file. Literal values remain saved in kiln.yaml and generated source.',
    'Run the app to check runtime support. Connections, permissions, and external service settings have not been checked.',
  }.toList();

  /// Reviews every declared prompt while preserving defaults and secret masks.
  Map<String, Object?> collect({
    required Map<String, Object?> saved,
    required Map<String, String> provided,
    required Prompter prompter,
    required bool interactive,
  }) {
    final answers = <String, Object?>{};
    for (final prompt in manifest.prompts) {
      final key = prompt.name;
      final supplied = provided['${manifest.id}.$key'] ?? provided[key];
      var current = saved.containsKey(key) ? saved[key] : prompt.defaultValue;
      final locales = answers['locales'];
      if (manifest.id == 'l10n' &&
          key == 'fallback_locale' &&
          locales is List &&
          locales.isNotEmpty &&
          !locales.contains(current)) {
        current = locales.first;
      }
      if (_issue(prompt, current) != null ||
          manifest.id == 'appwrite' &&
              AppwriteSetup({...AppwriteSetup.defaults, ...saved}).issues
                  .containsKey(key)) {
        current = null;
      }
      while (true) {
        Object? value;
        if (supplied != null) {
          value = parse(prompt, supplied);
        } else if (!interactive) {
          value = current;
        } else {
          if (prompt.description != null) prompter.say(prompt.description!);
          final options = prompt.options.isEmpty
              ? ''
              : ' (${prompt.options.join(', ')})';
          final hint = prompt.isMulti
              ? ' [comma separated; !clear empties the list]'
              : ' [!clear empties the setting]';
          final raw = prompter.text(
            '${prompt.label ?? key}$options$hint',
            defaultValue: current is List
                ? current.join(',')
                : current?.toString(),
            secret: isSecret(prompt),
            cancelOnEof: true,
            trimInput:
                prompt.type != PromptType.string &&
                prompt.type != PromptType.secret,
          );
          value = parse(prompt, raw == '!clear' ? '' : raw ?? '');
          if (raw == null && prompt.defaultValue == null && !prompt.required) {
            value = null;
          }
        }
        if (manifest.id == 'appwrite' && value is String) value = value.trim();
        final issue =
            _issue(prompt, value) ??
            (manifest.id == 'appwrite'
                ? AppwriteSetup({
                    ...AppwriteSetup.defaults,
                    ...saved,
                    key: value,
                  }).issues[key]
                : null);
        if (issue == null) {
          answers[key] = prompt.validate(value).value;
          break;
        }
        if (!interactive || supplied != null) {
          throw KilnException(
            issue,
            code: 'setup.invalid',
            suggestion: 'Run kiln setup ${manifest.id} --answer $key=<value>.',
          );
        }
        prompter.say(issue);
      }
    }
    final remaining = issues(answers);
    if (remaining.isNotEmpty) {
      throw KilnException(
        remaining.values.first,
        code: 'setup.invalid',
        suggestion: 'Review settings with kiln setup ${manifest.id}.',
      );
    }
    return answers;
  }
}
