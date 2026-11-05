import 'package:pub_semver/pub_semver.dart';

/// Version ranges an extension declares it supports.
final class Compatibility {
  const Compatibility({this.kiln, this.dart, this.flutter});

  final String? kiln;
  final String? dart;
  final String? flutter;

  bool get isEmpty => kiln == null && dart == null && flutter == null;

  /// Returns one message per incompatible or malformed constraint.
  List<String> problems({
    String? kilnVersion,
    String? dartVersion,
    String? flutterVersion,
  }) {
    return <String>[
      if (kiln != null) ..._check('kiln', kiln!, kilnVersion),
      if (dart != null) ..._check('Dart', dart!, dartVersion),
      if (flutter != null) ..._check('Flutter', flutter!, flutterVersion),
    ];
  }

  bool isCompatible({
    String? kilnVersion,
    String? dartVersion,
    String? flutterVersion,
  }) {
    return problems(
      kilnVersion: kilnVersion,
      dartVersion: dartVersion,
      flutterVersion: flutterVersion,
    ).isEmpty;
  }

  static Compatibility fromMap(Map<String, Object?> map) {
    return Compatibility(
      kiln: map['kiln'] as String?,
      dart: map['dart'] as String?,
      flutter: map['flutter'] as String?,
    );
  }

  List<String> _check(String label, String range, String? current) {
    if (current == null) {
      return const <String>[];
    }
    try {
      final constraint = VersionConstraint.parse(range);
      final version = Version.parse(current);
      if (constraint.allows(version)) {
        return const <String>[];
      }
      return <String>['$label $current does not satisfy $range'];
    } catch (_) {
      return <String>['$label constraint "$range" is malformed'];
    }
  }
}
