/// Creates stable notification ids from string keys.
final class NotificationIdAllocator {
  const NotificationIdAllocator();

  /// FNV-1a over UTF-16 code units, masked to a positive 31-bit id.
  int idFor(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
