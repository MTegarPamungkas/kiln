/// Why a set of extensions cannot be installed together.
enum ConflictKind {
  unknownExtension,
  missingCapability,
  duplicateCapability,
  exclusiveCategory,
  slotNotOpened,
  slotItemTypeMismatch,
  dependencyCycle,
}

/// One actionable installation conflict.
final class ResolutionConflict {
  const ResolutionConflict({
    required this.kind,
    required this.message,
    this.suggestion,
    this.extensionIds = const <String>[],
  });

  final ConflictKind kind;
  final String message;
  final String? suggestion;
  final List<String> extensionIds;

  String toText() {
    final hint = suggestion == null ? '' : '\n  hint: $suggestion';
    return '[${kind.name}] $message$hint';
  }

  @override
  String toString() => toText();
}

/// A resolution failure that carries every conflict found in one pass.
final class ResolutionException implements Exception {
  const ResolutionException(this.conflicts);

  final List<ResolutionConflict> conflicts;

  @override
  String toString() {
    final report = ConflictReport(conflicts).toText();
    return 'ResolutionException: $report';
  }
}

/// Formats conflicts for a terminal or a CI log.
final class ConflictReport {
  const ConflictReport(this.conflicts);

  final List<ResolutionConflict> conflicts;

  bool get isEmpty => conflicts.isEmpty;

  String toText() {
    if (conflicts.isEmpty) {
      return 'No conflicts.';
    }
    return conflicts.map((conflict) => conflict.toText()).join('\n\n');
  }
}
