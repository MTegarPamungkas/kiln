import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// [DeepLinks] whose links are emitted by the test.
final class FakeDeepLinks implements DeepLinks {
  FakeDeepLinks({this.initialLink});

  @override
  Uri? initialLink;
  final StreamController<Uri> _links = StreamController<Uri>.broadcast(
    sync: true,
  );
  bool disposed = false;

  @override
  Stream<Uri> get links => _links.stream;

  void emit(Uri link) {
    _links.add(link);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _links.close();
  }
}
