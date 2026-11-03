import 'patch.dart';

const String kIosAppDelegatePath = 'ios/Runner/AppDelegate.swift';

/// Adds the URL-opening override used by custom URL schemes.
final class IosAppDelegatePatch implements Patch {
  const IosAppDelegatePatch();

  @override
  String get id => 'ios.app_delegate.url_schemes';

  @override
  String get description => 'Forward opened URLs from AppDelegate';

  @override
  void apply(ProjectFiles files) {
    final content = files.read(kIosAppDelegatePath);
    if (content == null || content.contains('// kiln:url-schemes')) {
      return;
    }
    final close = content.lastIndexOf('}');
    if (close < 0) {
      return;
    }
    const block = '''
  // kiln:url-schemes
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
''';
    files.write(kIosAppDelegatePath, content.replaceRange(close, close, block));
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kIosAppDelegatePath);
    if (content == null) {
      return;
    }
    final pattern = RegExp(
      r'\n\s*// kiln:url-schemes.*?\n  \}\n',
      dotAll: true,
    );
    files.write(kIosAppDelegatePath, content.replaceAll(pattern, ''));
  }
}
