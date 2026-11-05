import 'package:kiln_core/kiln_core.dart';

/// Reports the native calendar capability.
final class CalendarSupport {
  const CalendarSupport();

  SupportInfo get info => const SupportInfo.supported(
    details: <String, Object?>{'system_calendar_ui': true},
  );
}
