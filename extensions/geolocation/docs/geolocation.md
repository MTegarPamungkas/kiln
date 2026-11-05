# Geolocation

`geolocation` provides the `LocationProvider` contract from `kiln_core`.

```dart
final location = registry.read<LocationProvider>();

final position = await location.current();
final updates = location.updates(
  accuracy: LocationAccuracy.high,
  distanceFilterMeters: 10,
);
```

## Permissions

When the `permission` extension is installed, the provider checks and requests
`PermissionKind.location` through that contract. Without it, the geolocator
plugin asks the platform directly.

Recommended native declarations:

- Android: `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION`.
- iOS: `NSLocationWhenInUseUsageDescription`.
- macOS: the location entitlement.

The extension adds these declarations automatically.

## Support

`GeolocationSupport` checks location services and permission during bootstrap:

- services off → `unavailable`
- permission denied → `permissionDenied`
- missing platform implementation → `unsupportedPlatform`

`updates()` remains a broadcast-safe plugin stream; cancel the subscription when
the screen is disposed.
