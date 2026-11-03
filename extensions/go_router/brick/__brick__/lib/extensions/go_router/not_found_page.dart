import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Friendly screen shown when no route matches the requested location.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({this.onHome, super.key});

  /// Overrides the default navigation back to [AppRoutes.home].
  final VoidCallback? onHome;

  static const Key pageKey = Key('not-found-page');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      key: pageKey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.travel_explore_rounded,
                    size: 72,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Halaman tidak ditemukan',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Alamat yang Anda buka tidak dikenali. Periksa kembali '
                    'tautannya atau kembali ke beranda.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onHome ?? () => context.go(AppRoutes.home),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Kembali ke beranda'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
