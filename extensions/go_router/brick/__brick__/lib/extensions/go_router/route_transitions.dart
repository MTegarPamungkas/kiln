import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builds a page whose transition follows the host platform conventions.
///
/// Use this from a `pageBuilder` when a route should animate instead of using
/// the default platform adapter page.
Page<Object?> buildRoutePage({
  required GoRouterState state,
  required Widget child,
  TargetPlatform? platform,
}) {
  final target = platform ?? defaultTargetPlatform;
  return CustomTransitionPage<Object?>(
    key: state.pageKey,
    name: state.name ?? state.path ?? state.uri.path,
    transitionDuration: _durationFor(target),
    reverseTransitionDuration: _durationFor(target),
    child: child,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => _transitionFor(target, animation, child),
  );
}

Duration _durationFor(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return const Duration(milliseconds: 350);
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
      return const Duration(milliseconds: 250);
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return const Duration(milliseconds: 180);
  }
}

Widget _transitionFor(
  TargetPlatform platform,
  Animation<double> animation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  );
  switch (platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return FadeTransition(opacity: curved, child: child);
  }
}
