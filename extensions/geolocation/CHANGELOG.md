# Changelog

## 0.1.1

- Add a 15-second time limit to current-position requests and return a retryable
  `Failure(unavailable)` when the device has no fix.

## 0.1.0

- Add `LocationProvider`, the geolocator gateway, permission-aware reads and
  streams, Android/iOS/macOS native setup, and runtime support reporting.
