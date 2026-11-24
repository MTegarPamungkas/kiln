import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:kiln_core/kiln_core.dart';

/// Matches the SDK client's development-only certificate policy.
http.Client createAppwriteLoginClient(AppFlavor flavor) {
  final native = io.HttpClient();
  if (flavor == AppFlavor.development) {
    native.badCertificateCallback = (_, _, _) => true;
  }
  return IOClient(native);
}
