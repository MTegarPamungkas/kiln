# Streams and permissions

`LocationProvider` has two modes: one position (`current`) and a stream of
positions (`updates`). Both ask for permission when needed; the support probe
does not.

## One position

```dart
final position = await gate.currentLocation(
  accuracy: LocationAccuracy.high,
);
position.fold(
  ok: (value) => save(value.latitude, value.longitude),
  err: (failure) => showFailure(failure),
);
```

## Continuous updates

```dart
final location = registry.read<LocationProvider>();
final subscription = location.updates(
  accuracy: LocationAccuracy.high,
  distanceFilterMeters: 10,
).listen(
  (position) => updateMap(position),
  onError: (Object error) => handleLocationError(error),
);

// Cancel when the screen is disposed.
await subscription.cancel();
```

- `distanceFilterMeters` reduces noise and battery use; `0` delivers every
  platform update.
- Higher accuracy can take longer and costs more battery.
- The stream is owned by the plugin; cancel it with the screen. The provider
  does not close a per-screen subscription for you.

## Permission and service state

The extension uses the `permission` contract when installed; otherwise it calls
the geolocator permission API. The bootstrap probe is cheap and does not prompt:

| State | SupportState |
| --- | --- |
| Location services off | `unavailable` |
| Permission denied | `permissionDenied` |
| No platform implementation | `unsupportedPlatform` |
| Ready | `supported` |

A call that cannot run throws `SupportInfo.toFailure()` or a location failure.
Use `gate.locationServiceEnabled()` to show a "enable location" action without
requesting permission.

## Native declarations

The brick adds:

- Android: `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION`.
- iOS: `NSLocationWhenInUseUsageDescription`.
- macOS: the location entitlement.

Add a "when in use" explanation in the app before the system prompt; the SDK
does not own rationale UI.

## Background and testing

Background location is platform-specific and can require a foreground service
or special permission. Keep tracking in the foreground unless the app has an
explicit background use case. Test permission denial, permanently denied, and
services-off paths on a real device; emulators often return a synthetic position.
