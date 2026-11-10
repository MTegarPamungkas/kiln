/// Rotating file output with a web-safe surface.
///
/// The VM selects the `dart:io` implementation; every other platform gets a
/// no-op stub, so importing this file never pulls `dart:io` into a web build.
library;

export 'file_log_sink_stub.dart' if (dart.library.io) 'file_log_sink_io.dart';
