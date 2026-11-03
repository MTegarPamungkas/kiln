import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import '../social_availability.dart';
import '../social_login_config.dart';

/// Google and Apple buttons, filtered by availability and configuration.
final class SocialLoginButtons extends StatefulWidget {
  const SocialLoginButtons({
    super.key,
    required this.login,
    required this.availability,
    required this.config,
    this.onCredential,
    this.onFailure,
  });

  final SocialLogin login;
  final SocialAvailability availability;
  final SocialLoginConfig config;
  final ValueChanged<SocialCredential?>? onCredential;
  final ValueChanged<Failure>? onFailure;

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

final class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  SocialProvider? _busy;

  List<SocialProvider> get _providers => SocialProvider.values
      .where((provider) => widget.config.isReady(provider, widget.availability))
      .toList(growable: false);

  Future<void> _signIn(SocialProvider provider) async {
    if (_busy != null) {
      return;
    }
    setState(() => _busy = provider);
    try {
      final credential = await widget.login.signIn(provider);
      widget.onCredential?.call(credential);
    } on Failure catch (failure) {
      widget.onFailure?.call(failure);
    } finally {
      if (mounted) {
        setState(() => _busy = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers = _providers;
    if (providers.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final provider in providers) ...<Widget>[
          FilledButton.icon(
            key: ValueKey<String>('social-login-${provider.name}'),
            onPressed: _busy == null ? () => _signIn(provider) : null,
            icon: _busy == provider
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_icon(provider)),
            label: Text(_label(provider)),
          ),
          if (provider != providers.last) const SizedBox(height: 10),
        ],
      ],
    );
  }

  IconData _icon(SocialProvider provider) {
    return switch (provider) {
      SocialProvider.google => Icons.g_mobiledata,
      SocialProvider.apple => Icons.apple,
    };
  }

  String _label(SocialProvider provider) {
    return switch (provider) {
      SocialProvider.google => 'Lanjut dengan Google',
      SocialProvider.apple => 'Lanjut dengan Apple',
    };
  }
}
