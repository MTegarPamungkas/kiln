import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

/// Device and platform support for each media source.
final class MediaPickerSupport {
  const MediaPickerSupport({required this.platform, this.isWeb = false});

  factory MediaPickerSupport.current() {
    return MediaPickerSupport(platform: defaultTargetPlatform, isWeb: kIsWeb);
  }

  final TargetPlatform platform;
  final bool isWeb;

  SupportInfo forSource(MediaSource source) {
    if (source == MediaSource.gallery) {
      return const SupportInfo.supported();
    }
    if (isWeb) {
      return const SupportInfo.supported();
    }
    return switch (platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => const SupportInfo.supported(),
      TargetPlatform.windows ||
      TargetPlatform.linux => const SupportInfo.unsupported(
        SupportState.unsupportedDevice,
        message: 'Camera capture is not supported on this desktop.',
      ),
      TargetPlatform.fuchsia => const SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Camera capture is not supported on this platform.',
      ),
    };
  }

  SupportInfo get overall => SupportInfo.supported(
    details: <String, Object?>{
      'camera': forSource(MediaSource.camera).state.name,
      'gallery': forSource(MediaSource.gallery).state.name,
    },
  );
}
