import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform options and prefix for secure storage.
final class SecureStorageConfig {
  const SecureStorageConfig({
    this.prefix = '{{app_name}}.',
    this.android = const AndroidOptions(),
    this.ios = const IOSOptions(),
    this.web = const WebOptions(),
  });

  static const defaults = SecureStorageConfig();

  final String prefix;
  final AndroidOptions android;
  final IOSOptions ios;
  final WebOptions web;
}
