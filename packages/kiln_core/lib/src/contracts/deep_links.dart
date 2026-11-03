/// Receives links that open the application.
abstract interface class DeepLinks {
  /// The link that launched the application, if any.
  Uri? get initialLink;

  Stream<Uri> get links;

  Future<void> dispose();
}
