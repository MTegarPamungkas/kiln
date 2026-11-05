/// A failure raised by the SDK with a stable code and an actionable hint.
final class KilnException implements Exception {
  const KilnException(
    this.message, {
    this.code = 'kiln.error',
    this.suggestion,
    this.details = const <String, Object?>{},
  });

  final String message;
  final String code;
  final String? suggestion;
  final Map<String, Object?> details;

  @override
  String toString() {
    final hint = suggestion == null ? '' : '\nHint: $suggestion';
    return 'KilnException($code): $message$hint';
  }
}
