/// Platform link source that can be faked in tests.
abstract interface class AppLinksGateway {
  /// The link that launched the application, if any.
  Future<Uri?> initialLink();

  /// Links that arrive while the application is running.
  Stream<Uri> get links;

  Future<void> dispose();
}
