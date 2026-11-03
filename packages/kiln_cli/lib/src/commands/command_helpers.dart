import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

import '../bundles/catalog.g.dart';
import '../infra/kiln_logger.dart';
import '../infra/prompter.dart';

/// Extensions shipped inside this CLI build.
List<AvailableExtension> get extensionCatalog => bundledExtensions;

AvailableExtension? findAvailableExtension(String id) {
  for (final extension in bundledExtensions) {
    if (extension.id == id) {
      return extension;
    }
  }
  return null;
}

Map<String, String> parseAnswerOptions(List<String> rawAnswers) {
  final answers = <String, String>{};
  for (final raw in rawAnswers) {
    final index = raw.indexOf('=');
    if (index <= 0) {
      throw KilnException(
        'Format --answer harus nama=nilai, diterima "$raw"',
        code: 'prompt.invalid',
      );
    }
    answers[raw.substring(0, index)] = raw.substring(index + 1);
  }
  return answers;
}

Map<String, Object?> answerForExtension(
  AvailableExtension extension, {
  required Map<String, Object?> saved,
  required Map<String, String> provided,
  required Prompter prompter,
}) {
  final answers = <String, Object?>{...saved};
  for (final prompt in extension.manifest.prompts) {
    if (answers.containsKey(prompt.name)) {
      continue;
    }

    final providedRaw =
        provided['${extension.id}.${prompt.name}'] ?? provided[prompt.name];
    if (providedRaw != null) {
      final value = _parseProvided(prompt, providedRaw);
      final validation = prompt.validate(value);
      if (!validation.isValid) {
        throw KilnException(
          '${extension.id}: ${validation.error}',
          code: 'prompt.invalid',
        );
      }
      answers[prompt.name] = validation.value;
      continue;
    }

    if (prompt.defaultValue != null) {
      answers[prompt.name] = prompt.defaultValue;
      continue;
    }
    if (!prompt.required) {
      continue;
    }
    if (!prompter.interactive) {
      throw KilnException(
        '${extension.id}: prompt "${prompt.name}" wajib diisi',
        code: 'prompt.required',
        suggestion: 'Add --answer ${prompt.name}=<value>',
      );
    }

    final label = prompt.label ?? prompt.name;
    final answer = switch (prompt.type) {
      PromptType.intValue => prompter.integer(
        label,
        min: prompt.min,
        max: prompt.max,
      ),
      PromptType.boolValue => prompter.confirm(label),
      PromptType.enumValue => prompter.select(label, prompt.options),
      PromptType.multi =>
        prompter
            .text('$label (comma separated)')
            ?.split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
      PromptType.secret => prompter.text(label, secret: true),
      PromptType.string || PromptType.url => prompter.text(label),
    };
    final validation = prompt.validate(answer);
    if (!validation.isValid) {
      throw KilnException(
        '${extension.id}: ${validation.error}',
        code: 'prompt.invalid',
      );
    }
    answers[prompt.name] = validation.value;
  }
  return answers;
}

Map<String, Map<String, Object?>> answersForPlan(
  List<AvailableExtension> extensions, {
  required Map<String, Map<String, Object?>> saved,
  required Map<String, String> provided,
  required Prompter prompter,
}) {
  return <String, Map<String, Object?>>{
    for (final extension in extensions)
      extension.id: answerForExtension(
        extension,
        saved: saved[extension.id] ?? const <String, Object?>{},
        provided: provided,
        prompter: prompter,
      ),
  };
}

Object? _parseProvided(PromptSpec prompt, String raw) {
  if (prompt.isMulti) {
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }
  if (prompt.type == PromptType.intValue) {
    return int.tryParse(raw) ?? raw;
  }
  if (prompt.type == PromptType.boolValue) {
    if (raw == 'true' || raw == '1' || raw == 'yes') {
      return true;
    }
    if (raw == 'false' || raw == '0' || raw == 'no') {
      return false;
    }
    return raw;
  }
  return raw;
}

void printChanges(KilnLogger logger, List<FileChange> changes) {
  for (final change in changes) {
    logger.info('  ${change.label.padRight(10)} ${change.path}');
  }
}

void printWarnings(KilnLogger logger, Iterable<String> warnings) {
  for (final warning in warnings) {
    logger.warn(warning);
  }
}

void printManualSteps(KilnLogger logger, Iterable<PlannedManualStep> steps) {
  if (steps.isEmpty) {
    return;
  }
  logger.info('Manual steps:');
  for (final step in steps) {
    logger.info('  - ${step.step.description}');
  }
}
