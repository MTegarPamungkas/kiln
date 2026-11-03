import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Reports the device timezone identifier.
abstract interface class TimezoneSource {
  Future<String?> localIdentifier();
}

/// Reads the identifier from flutter_timezone.
final class FlutterTimezoneSource implements TimezoneSource {
  const FlutterTimezoneSource();

  @override
  Future<String?> localIdentifier() async {
    final info = await FlutterTimezone.getLocalTimezone();
    return info.identifier;
  }
}

/// Configures the timezone database with the device location.
final class TimezoneResolver {
  TimezoneResolver({TimezoneSource? source})
    : _source = source ?? const FlutterTimezoneSource();

  final TimezoneSource _source;
  bool _initialized = false;

  /// Returns true when the device timezone was applied.
  Future<bool> configure() async {
    if (_initialized) {
      return true;
    }
    tz_data.initializeTimeZones();
    final identifier = await _source.localIdentifier();
    if (identifier == null || identifier.isEmpty) {
      return false;
    }
    try {
      tz.setLocalLocation(tz.getLocation(identifier));
    } on Object {
      return false;
    }
    _initialized = true;
    return true;
  }

  tz.TZDateTime toLocal(DateTime when) => tz.TZDateTime.from(when, tz.local);

  tz.TZDateTime now() => tz.TZDateTime.now(tz.local);
}
