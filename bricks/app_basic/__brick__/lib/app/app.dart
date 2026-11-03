import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import '../core/session/session_expiry_guard.dart';
import 'app_shell.dart';
import 'registry_scope.dart';

/// Root widget that makes the bootstrap [Registry] available to the tree.
class KilnApp extends StatefulWidget {
  const KilnApp({required this.registry, super.key});

  final Registry registry;

  @override
  State<KilnApp> createState() => _KilnAppState();
}

class _KilnAppState extends State<KilnApp> with WidgetsBindingObserver {
  late final LifecycleController _lifecycle;
  late final SessionExpiryGuard _expiry;

  @override
  void initState() {
    super.initState();
    _lifecycle = widget.registry.read<LifecycleController>();
    _expiry = SessionExpiryGuard(
      session: widget.registry.read<SessionController>(),
      clock: widget.registry.read<Clock>(),
    )..start();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_lifecycle.onResume());
        _expiry.checkNow();
      case AppLifecycleState.paused:
        unawaited(_lifecycle.onPause());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_expiry.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RegistryScope(registry: widget.registry, child: const AppShell());
  }
}
