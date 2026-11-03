import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import '../social_availability.dart';
import '../social_login_config.dart';
import 'social_login_buttons.dart';

/// Ready-to-use panel with the social buttons and a failure message.
final class SocialLoginPanel extends StatefulWidget {
  const SocialLoginPanel({
    super.key,
    required this.login,
    required this.availability,
    required this.config,
    this.title = 'Masuk cepat',
    this.onCredential,
  });

  final SocialLogin login;
  final SocialAvailability availability;
  final SocialLoginConfig config;
  final String title;
  final ValueChanged<SocialCredential?>? onCredential;

  @override
  State<SocialLoginPanel> createState() => _SocialLoginPanelState();
}

final class _SocialLoginPanelState extends State<SocialLoginPanel> {
  Failure? _failure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = _failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        SocialLoginButtons(
          login: widget.login,
          availability: widget.availability,
          config: widget.config,
          onCredential: (credential) {
            setState(() => _failure = null);
            widget.onCredential?.call(credential);
          },
          onFailure: (failure) => setState(() => _failure = failure),
        ),
        if (failure != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            failure.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
