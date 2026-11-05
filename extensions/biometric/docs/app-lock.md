# App lock

`AppLock` locks the application when the user leaves it for longer than
`grace_seconds`. The extension owns the lock state; the application owns the
lock screen, its copy, and its styling.

The flow:

1. The application forwards the `paused` lifecycle event to `AppLock`.
2. On `resumed`, `AppLock` compares the elapsed time with the grace period.
3. When the limit is exceeded, `AppLock.locked` becomes true.
4. The application shows its own lock screen while `locked` is true.
5. Its unlock action calls `AppLock.unlock()`, which authenticates through
   `BiometricGate`.
6. If authentication succeeds, `locked` becomes false; if it fails, the screen
   stays.

```dart
class MyLockGate extends StatefulWidget {
  const MyLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<MyLockGate> createState() => _MyLockGateState();
}

class _MyLockGateState extends State<MyLockGate>
    with WidgetsBindingObserver {
  late final AppLock _lock;

  @override
  void initState() {
    super.initState();
    _lock = RegistryScope.read<AppLock>(context);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_lock.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _lock.onPause();
      case AppLifecycleState.resumed:
        unawaited(_lock.onResume());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _lock.locked,
      builder: (context, locked, child) {
        return locked ? const MyLockScreen() : child!;
      },
      child: widget.child,
    );
  }
}
```

Place the gate inside `MaterialApp.builder` so the lock screen inherits the
application theme and localizations:

```dart
MaterialApp.router(
  builder: (context, child) => MyLockGate(child: child ?? const SizedBox()),
  routerConfig: router,
)
```

The gate must call `AppLock.initialize()`. It disables the lock automatically
when the device has no usable biometrics, so `unlock()` never blocks a device
without hardware.

## Grace period

The grace period prevents the lock from appearing when the user merely opens the
camera or a system permission dialog. A value of 0 locks every time the
application returns from the background.
