/// Position requested from the device location provider.
enum LocationAccuracy { lowest, low, medium, high, best }

/// One geographic position reported by the device.
final class GeoPosition {
  const GeoPosition({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyMeters,
    this.altitudeMeters,
    this.headingDegrees,
    this.speedMetersPerSecond,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracyMeters;
  final double? altitudeMeters;
  final double? headingDegrees;
  final double? speedMetersPerSecond;

  @override
  String toString() =>
      'GeoPosition($latitude, $longitude, accuracy: $accuracyMeters)';
}

/// Reads the current location and streams updates from the device.
abstract interface class LocationProvider {
  /// Whether the platform location service is enabled.
  Future<bool> isServiceEnabled();

  /// Requests permission when needed and returns one position.
  Future<GeoPosition> current({
    LocationAccuracy accuracy = LocationAccuracy.high,
  });

  /// Streams positions after permission is granted.
  Stream<GeoPosition> updates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 0,
  });
}
