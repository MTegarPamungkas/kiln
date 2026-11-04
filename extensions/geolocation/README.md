# geolocation

Device location behind the `LocationProvider` contract.

- `LocationProvider.current()` requests permission and returns one position.
- `LocationProvider.updates()` streams positions with an accuracy and distance
  filter.
- Uses the `permission` contract when installed; otherwise falls back to the
  geolocator permission API.
- Reports service/permission readiness through `SupportRegistry`.

```bash
kiln add geolocation
```

## Gate

```dart
final position = await gate.currentLocation();        // Result<GeoPosition>
final enabled = await gate.locationServiceEnabled();  // Result<bool>

// Streaming is not a Result verb; read the contract directly:
gate.location.updates(distanceFilterMeters: 10).listen((p) => ...);
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
The probe checks location services and permission without prompting. Location
services off → `unavailable`; permission denied → `permissionDenied`; missing
platform implementation → `unsupportedPlatform`.

See [support and devices](../../docs/extensions/support-and-devices.md).
