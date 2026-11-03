/// A broadcast receiver declared by an extension.
final class AndroidReceiverSetup {
  const AndroidReceiverSetup({
    required this.name,
    this.exported = false,
    this.actions = const <String>[],
  });

  final String name;
  final bool exported;
  final List<String> actions;

  static AndroidReceiverSetup? fromMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    final name = value['name'];
    if (name is! String || name.isEmpty) {
      return null;
    }
    return AndroidReceiverSetup(
      name: name,
      exported: value['exported'] == true,
      actions: _stringList(value['actions']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      if (exported) 'exported': true,
      if (actions.isNotEmpty) 'actions': actions,
    };
  }
}

/// Native setup for Android.
final class AndroidSetup {
  const AndroidSetup({
    this.permissions = const <String>[],
    this.urlSchemes = const <String>[],
    this.appLinkHosts = const <String>[],
    this.appLinkPathPrefixes = const <String>[],
    this.receivers = const <AndroidReceiverSetup>[],
    this.allowBackup,
    this.activity,
    this.minSdk,
  });

  final List<String> permissions;
  final List<String> urlSchemes;
  final List<String> appLinkHosts;
  final List<String> appLinkPathPrefixes;
  final List<AndroidReceiverSetup> receivers;
  final bool? allowBackup;
  final String? activity;
  final int? minSdk;

  bool get isEmpty =>
      permissions.isEmpty &&
      urlSchemes.isEmpty &&
      appLinkHosts.isEmpty &&
      receivers.isEmpty &&
      allowBackup == null &&
      activity == null &&
      minSdk == null;

  static AndroidSetup fromMap(Map<String, Object?> map) {
    final appLinks = _asMap(map['app_links']);
    return AndroidSetup(
      permissions: _stringList(map['permissions']),
      urlSchemes: _stringList(map['url_schemes']),
      appLinkHosts: _stringList(appLinks['hosts']),
      appLinkPathPrefixes: _stringList(appLinks['path_prefixes']),
      receivers: _receiverList(map['receivers']),
      allowBackup: map['allow_backup'] as bool?,
      activity: map['activity'] as String?,
      minSdk: _asInt(map['min_sdk']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (permissions.isNotEmpty) 'permissions': permissions,
      if (urlSchemes.isNotEmpty) 'url_schemes': urlSchemes,
      if (appLinkHosts.isNotEmpty)
        'app_links': <String, Object?>{
          'hosts': appLinkHosts,
          if (appLinkPathPrefixes.isNotEmpty)
            'path_prefixes': appLinkPathPrefixes,
        },
      if (receivers.isNotEmpty)
        'receivers': receivers
            .map((receiver) => receiver.toJson())
            .toList(growable: false),
      if (allowBackup != null) 'allow_backup': allowBackup,
      if (activity != null) 'activity': activity,
      if (minSdk != null) 'min_sdk': minSdk,
    };
  }
}

/// Native setup for iOS.
final class IosSetup {
  const IosSetup({
    this.plist = const <String, Object?>{},
    this.podfilePermissions = const <String>[],
    this.associatedDomains = const <String>[],
    this.entitlements = const <String, Object?>{},
    this.urlSchemes = const <String>[],
  });

  final Map<String, Object?> plist;
  final List<String> podfilePermissions;
  final List<String> associatedDomains;
  final Map<String, Object?> entitlements;
  final List<String> urlSchemes;

  bool get isEmpty =>
      plist.isEmpty &&
      podfilePermissions.isEmpty &&
      associatedDomains.isEmpty &&
      entitlements.isEmpty &&
      urlSchemes.isEmpty;

  static IosSetup fromMap(Map<String, Object?> map) {
    return IosSetup(
      plist: _asMap(map['plist']),
      podfilePermissions: _stringList(map['podfile_permissions']),
      associatedDomains: _stringList(map['associated_domains']),
      entitlements: _asMap(map['entitlements']),
      urlSchemes: _stringList(map['url_schemes']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (plist.isNotEmpty) 'plist': plist,
      if (podfilePermissions.isNotEmpty)
        'podfile_permissions': podfilePermissions,
      if (associatedDomains.isNotEmpty) 'associated_domains': associatedDomains,
      if (entitlements.isNotEmpty) 'entitlements': entitlements,
      if (urlSchemes.isNotEmpty) 'url_schemes': urlSchemes,
    };
  }
}

/// Native setup for macOS.
final class MacosSetup {
  const MacosSetup({
    this.entitlements = const <String, Object?>{},
    this.urlSchemes = const <String>[],
  });

  final Map<String, Object?> entitlements;
  final List<String> urlSchemes;

  bool get isEmpty => entitlements.isEmpty && urlSchemes.isEmpty;

  static MacosSetup fromMap(Map<String, Object?> map) {
    return MacosSetup(
      entitlements: _asMap(map['entitlements']),
      urlSchemes: _stringList(map['url_schemes']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (entitlements.isNotEmpty) 'entitlements': entitlements,
      if (urlSchemes.isNotEmpty) 'url_schemes': urlSchemes,
    };
  }
}

/// Native setup for the web runner.
final class WebSetup {
  const WebSetup({this.indexHtml = false});

  final bool indexHtml;

  bool get isEmpty => !indexHtml;

  static WebSetup fromMap(Map<String, Object?> map) {
    return WebSetup(indexHtml: map['index_html'] == true);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{if (indexHtml) 'index_html': true};
  }
}

/// Native setup that only applies when prompt answers match [when].
///
/// Each key in [when] is a prompt name; the entry matches when every answer
/// equals the expected value. Lists compare element by element.
final class NativeConditionalSetup {
  const NativeConditionalSetup({
    this.when = const <String, Object?>{},
    this.android = const AndroidSetup(),
    this.ios = const IosSetup(),
    this.macos = const MacosSetup(),
    this.web = const WebSetup(),
  });

  final Map<String, Object?> when;
  final AndroidSetup android;
  final IosSetup ios;
  final MacosSetup macos;
  final WebSetup web;

  bool get isEmpty =>
      android.isEmpty && ios.isEmpty && macos.isEmpty && web.isEmpty;

  bool matches(Map<String, Object?> answers) {
    if (when.isEmpty) {
      return false;
    }
    for (final entry in when.entries) {
      if (!answers.containsKey(entry.key)) {
        return false;
      }
      if (!_matchesAnswer(entry.value, answers[entry.key])) {
        return false;
      }
    }
    return true;
  }

  static NativeConditionalSetup fromMap(Map<String, Object?> map) {
    return NativeConditionalSetup(
      when: _asMap(map['when']),
      android: AndroidSetup.fromMap(_asMap(map['android'])),
      ios: IosSetup.fromMap(_asMap(map['ios'])),
      macos: MacosSetup.fromMap(_asMap(map['macos'])),
      web: WebSetup.fromMap(_asMap(map['web'])),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'when': when,
      if (!android.isEmpty) 'android': android.toJson(),
      if (!ios.isEmpty) 'ios': ios.toJson(),
      if (!macos.isEmpty) 'macos': macos.toJson(),
      if (!web.isEmpty) 'web': web.toJson(),
    };
  }
}

bool _matchesAnswer(Object? expected, Object? actual) {
  if (expected == null || actual == null) {
    return expected == actual;
  }
  if (expected is Iterable) {
    if (actual is! Iterable) {
      return false;
    }
    final expectedItems = expected.toList(growable: false);
    final actualItems = actual.toList(growable: false);
    if (expectedItems.length != actualItems.length) {
      return false;
    }
    for (var index = 0; index < expectedItems.length; index++) {
      if (!_matchesAnswer(expectedItems[index], actualItems[index])) {
        return false;
      }
    }
    return true;
  }
  if (actual is Iterable) {
    return false;
  }
  return '$actual' == '$expected';
}

/// All native setup declared by one extension manifest.
final class PlatformSetup {
  const PlatformSetup({
    this.android = const AndroidSetup(),
    this.ios = const IosSetup(),
    this.macos = const MacosSetup(),
    this.web = const WebSetup(),
    this.conditionals = const <NativeConditionalSetup>[],
    this.platforms = const <String>[],
  });

  final AndroidSetup android;
  final IosSetup ios;
  final MacosSetup macos;
  final WebSetup web;

  /// Native entries applied only when their prompt answers match.
  final List<NativeConditionalSetup> conditionals;

  /// Platforms the extension supports. Empty means every platform.
  final List<String> platforms;

  bool supports(String platform) =>
      platforms.isEmpty || platforms.contains(platform);

  bool get isEmpty =>
      android.isEmpty &&
      ios.isEmpty &&
      macos.isEmpty &&
      web.isEmpty &&
      conditionals.isEmpty;

  static PlatformSetup fromMap({
    Map<String, Object?>? android,
    Map<String, Object?>? ios,
    Map<String, Object?>? macos,
    Map<String, Object?>? web,
    List<Object?> conditionals = const <Object?>[],
    List<String> platforms = const <String>[],
  }) {
    return PlatformSetup(
      android: AndroidSetup.fromMap(android ?? const <String, Object?>{}),
      ios: IosSetup.fromMap(ios ?? const <String, Object?>{}),
      macos: MacosSetup.fromMap(macos ?? const <String, Object?>{}),
      web: WebSetup.fromMap(web ?? const <String, Object?>{}),
      conditionals: conditionals
          .map((entry) => NativeConditionalSetup.fromMap(_asMap(entry)))
          .toList(growable: false),
      platforms: platforms,
    );
  }
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, entry) => MapEntry('$key', entry));
  }
  return const <String, Object?>{};
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) {
    return const <String>[];
  }
  return value.map((entry) => '$entry').toList(growable: false);
}

List<AndroidReceiverSetup> _receiverList(Object? value) {
  if (value is! Iterable) {
    return const <AndroidReceiverSetup>[];
  }
  return value
      .map(AndroidReceiverSetup.fromMap)
      .whereType<AndroidReceiverSetup>()
      .toList(growable: false);
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  return value == null ? null : int.tryParse('$value');
}
