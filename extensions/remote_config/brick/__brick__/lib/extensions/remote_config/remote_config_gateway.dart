/// Source of remote JSON values, replaceable with a fake in tests.
abstract interface class RemoteConfigGateway {
  /// Fetches a JSON object of values from [url], honoring an optional
  /// [timeout]. Throws a [Failure] on transport, timeout, or status errors.
  Future<Map<String, Object?>> load(String url, {Duration? timeout});

  /// Releases the underlying HTTP client.
  Future<void> close();
}
