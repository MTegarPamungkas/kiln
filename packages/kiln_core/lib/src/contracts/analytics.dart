/// Records product events and identifies the signed-in user.
abstract interface class Analytics {
  Future<void> capture(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  });

  Future<void> identify(
    String userId, {
    Map<String, Object?> traits = const <String, Object?>{},
  });

  Future<void> reset();
}
