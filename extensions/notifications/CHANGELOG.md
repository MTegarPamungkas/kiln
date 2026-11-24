# Changelog

## 0.1.3

- Widen `flutter_local_notifications` constraint to `>=22.3.3 <24.0.0` so it
  allows 23.x while staying compatible with `appwrite` 28.x.

## 0.1.2

- Repack archive with deterministic cross-OS gzip and without root `test/`.

## 0.1.1

- Initialization stops before attaching the tap hub if the module was
  disposed while the plugin was starting.
- Buffer taps during gaps between listeners so router replacement does not
  silently discard a notification destination.
- Replay buffered launch taps after listen returns, preserving order when a
  live tap arrives during replay and avoiding emissions after disposal.
- The module disposes its tap hub, stream subscriptions, and gateway on
  shutdown.
- The launch payload and taps received before the first listener are retained
  and replayed once, so a router that subscribes during a later bootstrap phase
  still receives the launch route.

## 0.1.0

- Declare core library desugaring through native setup for existing Flutter apps.
- Initial release.
