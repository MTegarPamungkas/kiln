/// Holds links that arrive before the first listener is attached.
///
/// [release] replays the buffered links once; afterwards [add] is ignored so a
/// cancelled subscription cannot grow the buffer without a bound.
final class PendingLinkBuffer {
  PendingLinkBuffer({this.capacity = 16}) : assert(capacity > 0, 'capacity must be positive');

  final int capacity;
  final List<Uri> _links = <Uri>[];
  bool _released = false;

  /// Whether links are still being buffered.
  bool get isBuffering => !_released;

  /// Whether at least one link waits for a listener.
  bool get hasPending => _links.isNotEmpty;

  /// Number of buffered links.
  int get length => _links.length;

  /// Buffered links in arrival order.
  List<Uri> get pending => List<Uri>.unmodifiable(_links);

  /// Buffers [link], dropping the oldest link when [capacity] is reached.
  void add(Uri link) {
    if (_released) {
      return;
    }
    if (_links.length >= capacity) {
      _links.removeAt(0);
    }
    _links.add(link);
  }

  /// Returns the buffered links and stops buffering.
  List<Uri> release() {
    if (_released) {
      return const <Uri>[];
    }
    _released = true;
    final links = List<Uri>.unmodifiable(_links);
    _links.clear();
    return links;
  }

  /// Drops the buffered links without releasing them.
  void clear() => _links.clear();
}
