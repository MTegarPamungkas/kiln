/// A failure raised by `kiln_store` with a stable code and an actionable hint.
///
/// Store failures use their own type because the SDK exception is final, but
/// they keep the same `code`/`message`/`suggestion` shape so callers can handle
/// both uniformly.
final class KilnStoreException implements Exception {
  const KilnStoreException(
    this.message, {
    this.code = 'store.error',
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
    return 'KilnStoreException($code): $message$hint';
  }
}
