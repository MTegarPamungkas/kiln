/// The platform the app is currently running on.
///
/// One of `android`, `ios`, `macos`, `windows`, `linux`, `fuchsia`, `web`, or
/// `unknown`. Used by [KilnBootstrap] to skip modules that do not support the
/// current platform.
String get currentPlatform => 'web';
