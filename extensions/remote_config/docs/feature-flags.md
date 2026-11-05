# Feature flags

Use `remote_config` to gate application features without shipping a build. The
SDK returns values; the app decides what to do with them — no widgets are
provided.

## Gating a feature

```dart
final beta = gate.featureEnabled('beta_checkout');
if (beta) {
  // show the app-owned beta flow
}
```

`featureEnabled` reads the active snapshot and returns `defaultValue` until the
first successful `fetchRemoteConfig`, so the app always has a deterministic value
on cold start.

## Tunable values

```dart
final dailyLimit = gate.remoteConfigInt('daily_limit', defaultValue: 10);
final banner = gate.remoteConfigString('promotion_banner');
final themeConfig = gate.remoteConfigJson('theme', defaultValue: {'mode': 'light'});
```

## Reacting to updates

```dart
gate.remoteConfigChanges.listen((_) {
  // recompute flag-driven state; the app re-renders its own widgets
});
```

## Safe defaults

Register fallbacks once, at bootstrap, so a first-ever fetch failure still yields
sensible values:

```dart
gate.setRemoteDefaults(const {'beta_checkout': false, 'daily_limit': 10});
```

## Rollout tip

Keep the JSON flat and small (`{"flag": true, "limit": 10}`). Coercion handles
numbers stored as strings, but a flat map keeps every flag readable and cheap to
cache on device.
