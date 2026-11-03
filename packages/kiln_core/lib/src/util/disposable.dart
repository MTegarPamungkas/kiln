import 'dart:async';

/// Something that owns resources and must be released.
abstract interface class Disposable {
  FutureOr<void> dispose();
}
