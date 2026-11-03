import 'package:flutter/widgets.dart';

/// Landing page seam filled by the application.
///
/// The shell falls back to the starter page when no [AppHome] is registered.
abstract interface class AppHome {
  Widget build(BuildContext context);
}
