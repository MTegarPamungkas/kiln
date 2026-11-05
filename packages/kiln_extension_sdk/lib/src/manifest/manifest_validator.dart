import 'package:pub_semver/pub_semver.dart';

import '../kiln_exception.dart';
import 'extension_manifest.dart';
import 'platform_setup.dart';
import 'prompt_spec.dart';

/// Validates structural rules that JSON Schema cannot express on its own.
final class ManifestValidator {
  const ManifestValidator();

  static final RegExp _idPattern = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
  static final RegExp _capabilityPattern = RegExp(r'^[a-z][a-z0-9_.]*$');
  static final RegExp _packagePattern = RegExp(r'^[a-z][a-z0-9_]*$');
  static final RegExp _androidComponentPattern = RegExp(
    r'^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+$',
  );
  static final RegExp _permissionPattern = RegExp(
    r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$',
  );
  static final RegExp _urlSchemePattern = RegExp(r'^[a-z][a-z0-9+.-]*$');
  static final RegExp _hostPattern = RegExp(
    r'^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$',
  );
  static const Set<String> _platforms = <String>{
    'android',
    'ios',
    'macos',
    'web',
    'windows',
    'linux',
  };

  List<String> validate(ExtensionManifest manifest) {
    final errors = <String>[];

    if (!_idPattern.hasMatch(manifest.id)) {
      errors.add('id must be snake_case, got "${manifest.id}"');
    }
    if (manifest.name.trim().isEmpty) {
      errors.add('name must not be empty');
    }
    if (manifest.description.trim().isEmpty) {
      errors.add('description must not be empty');
    }
    if (manifest.category.trim().isEmpty) {
      errors.add('category must not be empty');
    }
    try {
      Version.parse(manifest.version);
    } catch (_) {
      errors.add('version must be semver, got "${manifest.version}"');
    }

    _validateCapabilities(manifest.provides, 'provides', errors);
    _validateCapabilities(manifest.requires, 'requires', errors);
    _validateCapabilities(
      manifest.optionalRequires,
      'optional_requires',
      errors,
    );

    final provided = manifest.provides.toSet();
    final overlapping = manifest.requires.where(provided.contains);
    for (final capability in overlapping) {
      errors.add('extension cannot require its own capability "$capability"');
    }

    final slotNames = <String>{};
    for (final slot in manifest.slots) {
      if (!_capabilityPattern.hasMatch(slot.name)) {
        errors.add('slot name "${slot.name}" is invalid');
      }
      if (!slotNames.add(slot.name)) {
        errors.add('slot "${slot.name}" is declared twice');
      }
      if (slot.item.trim().isEmpty) {
        errors.add('slot "${slot.name}" must declare an item type');
      }
    }

    for (final contribution in manifest.contributions) {
      if (!_capabilityPattern.hasMatch(contribution.slot)) {
        errors.add('contribution slot "${contribution.slot}" is invalid');
      }
      if (contribution.priority < 0) {
        errors.add(
          'contribution to "${contribution.slot}" has a negative priority',
        );
      }
    }

    final promptNames = <String>{};
    for (final prompt in manifest.prompts) {
      if (!_packagePattern.hasMatch(prompt.name)) {
        errors.add('prompt name "${prompt.name}" is invalid');
      }
      if (!promptNames.add(prompt.name)) {
        errors.add('prompt "${prompt.name}" is declared twice');
      }
      if ((prompt.type == PromptType.enumValue ||
              prompt.type == PromptType.multi) &&
          prompt.options.isEmpty) {
        errors.add('prompt "${prompt.name}" must declare options');
      }
      if (prompt.min != null &&
          prompt.max != null &&
          prompt.min! > prompt.max!) {
        errors.add('prompt "${prompt.name}" has min greater than max');
      }
    }

    for (final step in manifest.manualSteps) {
      if (!_packagePattern.hasMatch(step.id)) {
        errors.add('manual step id "${step.id}" is invalid');
      }
      if (step.description.trim().isEmpty) {
        errors.add('manual step "${step.id}" must have a description');
      }
    }

    for (final platform in manifest.platformSetup.platforms) {
      if (!_platforms.contains(platform)) {
        errors.add('unsupported platform "$platform"');
      }
    }

    _validateNativeSetup(
      android: manifest.platformSetup.android,
      ios: manifest.platformSetup.ios,
      macos: manifest.platformSetup.macos,
      errors: errors,
    );
    for (final conditional in manifest.platformSetup.conditionals) {
      if (conditional.when.isEmpty) {
        errors.add('conditional native setup must declare when');
      }
      for (final prompt in conditional.when.keys) {
        if (!manifest.promptsByName.containsKey(prompt)) {
          errors.add(
            'conditional native setup references unknown prompt "$prompt"',
          );
        }
      }
      if (conditional.isEmpty) {
        errors.add('conditional native setup has no platform entries');
      }
      _validateNativeSetup(
        android: conditional.android,
        ios: conditional.ios,
        macos: conditional.macos,
        errors: errors,
      );
    }

    final receiverNames = <String>{};
    for (final receiver in manifest.platformSetup.android.receivers) {
      if (!_androidComponentPattern.hasMatch(receiver.name)) {
        errors.add('Android receiver name "${receiver.name}" is invalid');
      }
      if (!receiverNames.add(receiver.name)) {
        errors.add('Android receiver "${receiver.name}" is declared twice');
      }
      final actions = <String>{};
      for (final action in receiver.actions) {
        if (!_androidComponentPattern.hasMatch(action)) {
          errors.add(
            'Android receiver "${receiver.name}" has invalid action "$action"',
          );
        }
        if (!actions.add(action)) {
          errors.add(
            'Android receiver "${receiver.name}" declares action "$action" '
            'twice',
          );
        }
      }
    }

    for (final dependency in manifest.dependencies.keys) {
      if (!_packagePattern.hasMatch(dependency)) {
        errors.add('dependency name "$dependency" is invalid');
      }
    }

    return errors;
  }

  void throwIfInvalid(ExtensionManifest manifest) {
    final errors = validate(manifest);
    if (errors.isEmpty) {
      return;
    }
    throw KilnException(
      'Invalid extension manifest for "${manifest.id}"',
      code: 'manifest.invalid',
      suggestion: errors.join('\n'),
      details: {'errors': errors},
    );
  }

  void _validateNativeSetup({
    required AndroidSetup android,
    required IosSetup ios,
    required MacosSetup macos,
    required List<String> errors,
  }) {
    _validateNativeValues(
      android.permissions,
      'Android permission',
      _permissionPattern,
      errors,
    );
    _validateNativeValues(
      android.urlSchemes,
      'Android URL scheme',
      _urlSchemePattern,
      errors,
    );
    _validateNativeValues(
      ios.urlSchemes,
      'iOS URL scheme',
      _urlSchemePattern,
      errors,
    );
    _validateNativeValues(
      macos.urlSchemes,
      'macOS URL scheme',
      _urlSchemePattern,
      errors,
    );
    _validateNativeValues(
      android.appLinkHosts,
      'Android App Link host',
      _hostPattern,
      errors,
    );
    _validateNativeValues(
      android.appLinkPathPrefixes,
      'Android App Link path prefix',
      RegExp(r'^/'),
      errors,
    );
  }

  void _validateNativeValues(
    List<String> values,
    String field,
    RegExp pattern,
    List<String> errors,
  ) {
    final seen = <String>{};
    for (final value in values) {
      if (!pattern.hasMatch(value)) {
        errors.add('$field "$value" is invalid');
      }
      if (!seen.add(value)) {
        errors.add('$field "$value" is duplicated');
      }
    }
  }

  void _validateCapabilities(
    List<String> capabilities,
    String field,
    List<String> errors,
  ) {
    final seen = <String>{};
    for (final capability in capabilities) {
      if (!_capabilityPattern.hasMatch(capability)) {
        errors.add('$field capability "$capability" is invalid');
      }
      if (!seen.add(capability)) {
        errors.add('$field capability "$capability" is duplicated');
      }
    }
  }
}
