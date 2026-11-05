import 'package:app_links/app_links.dart';

import 'deep_link_gateway.dart';

/// [AppLinksGateway] backed by the app_links plugin.
final class SdkAppLinksGateway implements AppLinksGateway {
  SdkAppLinksGateway({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> initialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;

  @override
  Future<void> dispose() async {
    // The app_links singleton owns its caches; there is nothing to release.
  }
}
