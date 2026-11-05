import 'package:kiln_core/kiln_core.dart';

import 'social_availability.dart';
import 'social_login_config.dart';

/// Per-provider support and configuration state.
final class SocialLoginSupport {
  const SocialLoginSupport({required this.config, required this.availability});

  final SocialLoginConfig config;
  final SocialAvailability availability;

  SupportInfo forProvider(SocialProvider provider) {
    if (!availability.supports(provider)) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message:
            '${_label(provider)} sign-in is not supported on this platform.',
        details: <String, Object?>{'provider': provider.name},
      );
    }
    if (!config.isEnabled(provider)) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: '${_label(provider)} sign-in is disabled in the app config.',
        details: <String, Object?>{'provider': provider.name},
      );
    }
    if (!config.isReady(provider, availability)) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: '${_label(provider)} client credentials are missing.',
        details: <String, Object?>{'provider': provider.name},
      );
    }
    return const SupportInfo.supported();
  }

  SupportInfo get overall {
    final states = <String, SupportInfo>{
      for (final provider in SocialProvider.values)
        provider.name: forProvider(provider),
    };
    final supported = <String>[
      for (final entry in states.entries)
        if (entry.value.isSupported) entry.key,
    ];
    if (supported.isNotEmpty) {
      return SupportInfo.supported(
        details: <String, Object?>{
          'supported_providers': supported,
          'providers': <String, Object?>{
            for (final entry in states.entries)
              entry.key: entry.value.state.name,
          },
        },
      );
    }
    final onlyPlatform = states.values.every(
      (info) => info.isPlatformUnsupported,
    );
    return SupportInfo.unsupported(
      onlyPlatform
          ? SupportState.unsupportedPlatform
          : SupportState.notConfigured,
      message: onlyPlatform
          ? 'Social sign-in is not supported on this platform.'
          : 'No social provider is configured for this platform.',
      details: <String, Object?>{
        'providers': <String, Object?>{
          for (final entry in states.entries) entry.key: entry.value.state.name,
        },
      },
    );
  }

  String _label(SocialProvider provider) {
    return switch (provider) {
      SocialProvider.google => 'Google',
      SocialProvider.apple => 'Apple',
    };
  }
}
