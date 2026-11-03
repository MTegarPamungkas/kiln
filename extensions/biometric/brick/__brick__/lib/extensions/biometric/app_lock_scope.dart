import 'dart:async';

import 'package:flutter/material.dart';

import 'app_lock.dart';

/// Covers the app with an unlock screen while [AppLock] is locked.
final class AppLockScope extends StatefulWidget {
  const AppLockScope({
    super.key,
    required this.appLock,
    required this.child,
    this.title = 'Aplikasi terkunci',
    this.message = 'Buka dengan biometrik untuk melanjutkan.',
    this.buttonLabel = 'Buka dengan biometrik',
  });

  final AppLock appLock;
  final Widget child;
  final String title;
  final String message;
  final String buttonLabel;

  @override
  State<AppLockScope> createState() => _AppLockScopeState();
}

final class _AppLockScopeState extends State<AppLockScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.appLock.locked.addListener(_onLockChanged);
    widget.appLock.enabled.addListener(_onLockChanged);
    unawaited(widget.appLock.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        widget.appLock.onPause();
      case AppLifecycleState.resumed:
        unawaited(widget.appLock.onResume());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onLockChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.appLock.locked.removeListener(_onLockChanged);
    widget.appLock.enabled.removeListener(_onLockChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          if (widget.appLock.isLocked)
            Material(
              color: Colors.black.withValues(alpha: 0.94),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: widget.appLock.unlock,
                        child: Text(widget.buttonLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
