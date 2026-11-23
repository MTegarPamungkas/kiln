import 'dart:convert';
import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:pub_semver/pub_semver.dart';

import '../version.dart';
import 'process_runner.dart';

/// Compatibility policy shared by planning, registry selection and doctor.
final class HostCompatibility {
  HostCompatibility(this.runner);

  final ProcessRunner runner;
  final _dart = Version.parse(Platform.version.split(' ').first);
  final _kiln = Version.parse(kilnVersion);
  Future<Version>? _flutter;

  Future<RegistryVersion?> select(
    RegistryExtension extension, {
    String? installedVersion,
    String? requestedVersion,
    String? capability,
  }) async {
    final needsFlutter = extension.versions.any(
      (version) => version.compatibility.containsKey('flutter'),
    );
    return const VersionResolver().resolve(
      extension,
      kilnVersion: _kiln,
      dartVersion: _dart,
      flutterVersion: needsFlutter
          ? await (_flutter ??= _flutterVersion())
          : null,
      installedVersion: installedVersion,
      requestedVersion: requestedVersion,
      capability: capability,
      allowPrerelease: requestedVersion != null,
    );
  }

  Future<List<String>> problems(ExtensionManifest manifest) async {
    final flutter = manifest.compatibility.flutter == null
        ? null
        : await (_flutter ??= _flutterVersion());
    return manifest.compatibility.problems(
      kilnVersion: _kiln.toString(),
      dartVersion: _dart.toString(),
      flutterVersion: flutter?.toString(),
    );
  }

  Future<void> check(
    Iterable<AvailableExtension> extensions,
    Iterable<String> platforms,
  ) async {
    for (final extension in extensions) {
      final manifest = extension.manifest;
      final issues = await problems(manifest);
      if (platforms.isNotEmpty &&
          !platforms.any(manifest.platformSetup.supports)) {
        issues.add(
          'supports none of the project platforms (${platforms.join(', ')})',
        );
      }
      if (issues.isNotEmpty) {
        throw KilnException(
          '${extension.id} ${manifest.version}: ${issues.join('; ')}',
          code: 'extension.incompatible',
          suggestion: 'Use a compatible extension version, toolchain or project platform.',
        );
      }
    }
  }

  Future<Version> _flutterVersion() async {
    try {
      final result = await runner.flutter(['--version', '--machine']);
      if (result.exitCode == 0) {
        final data = jsonDecode(result.stdout as String);
        if (data case {'frameworkVersion': final String version}) {
          return Version.parse(version);
        }
      }
    } on ProcessException {
      // Turn tool discovery failures into an actionable CLI diagnostic.
    } on FormatException {
      // Older or broken Flutter launches can return non-JSON output.
    }
    throw const KilnException(
      'Flutter version could not be determined.',
      code: 'toolchain.flutter_version',
      suggestion:
          'Run flutter --version --machine and verify Flutter is on PATH.',
    );
  }
}
