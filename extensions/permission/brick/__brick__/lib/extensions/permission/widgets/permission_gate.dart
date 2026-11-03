import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

/// Shows [child] only when the permission is granted.
class PermissionGate extends StatefulWidget {
  const PermissionGate({
    required this.permissions,
    required this.kind,
    required this.child,
    this.fallback,
    super.key,
  });

  final Permissions permissions;
  final PermissionKind kind;
  final Widget child;
  final Widget Function(BuildContext context)? fallback;

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  late Future<PermissionStatus> _status;

  @override
  void initState() {
    super.initState();
    _status = widget.permissions.status(widget.kind);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
      future: _status,
      builder: (context, snapshot) {
        if (snapshot.data?.isGranted == true) {
          return widget.child;
        }
        return widget.fallback?.call(context) ?? const SizedBox.shrink();
      },
    );
  }
}
