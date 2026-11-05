import 'package:kiln_core/kiln_core.dart';

/// Platform calendar access that can be faked in tests.
abstract interface class CalendarGateway {
  /// Returns false when the native calendar UI cannot be opened.
  Future<bool> add(CalendarEvent event);
}
