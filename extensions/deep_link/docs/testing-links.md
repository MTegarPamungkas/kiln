# Testing links

Always test with an installed application, not only from test code.

## Android

Custom scheme:

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "kiln://profile/42" com.example.app
```

Universal link:

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://kiln.dev/app/42" com.example.app
```

Without a package name, Android picks a matching application; this tests the
intent filter as well. Check domain verification with:

```bash
adb shell pm get-app-links com.example.app
```

## iOS

Simulator:

```bash
xcrun simctl openurl booted "kiln://profile/42"
xcrun simctl openurl booted "https://kiln.dev/app/42"
```

Device: send the link through Notes or Safari. Universal links cannot be tested
with `openurl` on every simulator version; use a device if the behavior feels
inconsistent.

## What to check

- The same link twice in a row is ignored (deduplication window).
- Links from other hosts are rejected without a crash.
- Paths outside `path_prefixes` are rejected.
- Links that arrive before the first screen is ready still reach the router.
- Launching the application from a link navigates only once (`initialLink`).
- `utm_*` parameters are gone from the URI received by the listener.
