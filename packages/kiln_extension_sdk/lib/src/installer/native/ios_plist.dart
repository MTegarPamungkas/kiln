import 'patch.dart';

const String kIosInfoPlistPath = 'ios/Runner/Info.plist';
const String kMacosInfoPlistPath = 'macos/Runner/Info.plist';

/// Creates a minimal plist document when the target file does not exist.
String ensurePlist(String? content) {
  if (content != null && content.trim().isNotEmpty) {
    return content;
  }
  return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
''';
}

String escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String plistValue(Object? value) {
  if (value is bool) {
    return value ? '<true/>' : '<false/>';
  }
  if (value is int) {
    return '<integer>$value</integer>';
  }
  if (value is double) {
    return '<real>$value</real>';
  }
  if (value is Map) {
    final buffer = StringBuffer('<dict>\n');
    for (final entry in value.entries) {
      buffer.writeln('  <key>${escapeXml('${entry.key}')}</key>');
      buffer.writeln('  ${plistValue(entry.value)}');
    }
    buffer.write('</dict>');
    return buffer.toString();
  }
  if (value is Iterable) {
    final buffer = StringBuffer('<array>\n');
    for (final item in value) {
      buffer.writeln('  ${plistValue(item)}');
    }
    buffer.write('</array>');
    return buffer.toString();
  }
  return '<string>${escapeXml('$value')}</string>';
}

String addPlistEntry(String content, String key, Object? value) {
  final keyTag = '<key>${escapeXml(key)}</key>';
  if (content.contains(keyTag)) {
    return content;
  }
  final index = content.lastIndexOf('</dict>');
  if (index < 0) {
    return content;
  }
  final entry = '  $keyTag\n  ${plistValue(value)}\n';
  return content.replaceRange(index, index, entry);
}

String removePlistEntry(String content, String key) {
  final keyTag = '<key>${escapeXml(key)}</key>';
  final keyStart = content.indexOf(keyTag);
  if (keyStart < 0) {
    return content;
  }
  var valueStart = keyStart + keyTag.length;
  while (valueStart < content.length && content[valueStart].trim().isEmpty) {
    valueStart++;
  }
  if (valueStart >= content.length || content[valueStart] != '<') {
    return content;
  }
  final valueEnd = elementEnd(content, valueStart);
  var start = keyStart;
  while (start > 0 && content[start - 1].trim().isEmpty) {
    start--;
  }
  return content.replaceRange(start, valueEnd, '');
}

int elementEnd(String content, int start) {
  final tagEnd = content.indexOf('>', start);
  if (tagEnd < 0) {
    return content.length;
  }
  if (content.substring(start, tagEnd + 1).endsWith('/>')) {
    return tagEnd + 1;
  }
  final tagMatch = RegExp(r'^<([A-Za-z0-9_]+)')
      .firstMatch(content.substring(start));
  final tag = tagMatch?.group(1);
  if (tag == null) {
    return tagEnd + 1;
  }
  final openPrefix = '<$tag';
  final closeTag = '</$tag>';
  var depth = 1;
  var index = tagEnd + 1;
  while (index < content.length) {
    final nextOpen = content.indexOf(openPrefix, index);
    final nextClose = content.indexOf(closeTag, index);
    if (nextClose < 0) {
      return content.length;
    }
    if (nextOpen >= 0 && nextOpen < nextClose) {
      final nestedEnd = content.indexOf('>', nextOpen);
      if (nestedEnd < 0) {
        return content.length;
      }
      if (!content.substring(nextOpen, nestedEnd + 1).endsWith('/>')) {
        depth++;
      }
      index = nestedEnd + 1;
    } else {
      depth--;
      index = nextClose + closeTag.length;
      if (depth == 0) {
        return index;
      }
    }
  }
  return content.length;
}

/// Adds one key to Info.plist.
final class IosPlistKeyPatch implements Patch {
  const IosPlistKeyPatch(this.key, this.value);

  final String key;
  final Object? value;

  @override
  String get id => 'ios.plist.$key';

  @override
  String get description => 'Add $key to Info.plist';

  @override
  void apply(ProjectFiles files) {
    final content = ensurePlist(files.read(kIosInfoPlistPath));
    files.write(kIosInfoPlistPath, addPlistEntry(content, key, value));
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kIosInfoPlistPath);
    if (content == null) {
      return;
    }
    files.write(kIosInfoPlistPath, removePlistEntry(content, key));
  }
}

/// Registers one custom URL scheme in CFBundleURLTypes.
/// Adds a URL scheme to a Runner `Info.plist`.
class PlistUrlSchemePatch implements Patch {
  const PlistUrlSchemePatch({
    required this.path,
    required this.platform,
    required this.platformName,
    required this.scheme,
  });

  final String path;
  final String platform;
  final String platformName;
  final String scheme;

  @override
  String get id => '$platform.url_scheme.$scheme';

  @override
  String get description => 'Add $platformName URL scheme $scheme';

  @override
  void apply(ProjectFiles files) {
    var content = ensurePlist(files.read(path));
    final keyTag = '<key>CFBundleURLTypes</key>';
    final keyIndex = content.indexOf(keyTag);
    if (keyIndex < 0) {
      content = addPlistEntry(content, 'CFBundleURLTypes', <Object?>[
        <String, Object?>{
          'CFBundleTypeRole': 'Editor',
          'CFBundleURLSchemes': <String>[scheme],
        },
      ]);
      files.write(path, content);
      return;
    }

    final arrayStart = _skipWhitespace(content, keyIndex + keyTag.length);
    final arrayEnd = elementEnd(content, arrayStart);
    if (content
        .substring(arrayStart, arrayEnd)
        .contains('<string>$scheme</string>')) {
      return;
    }
    final closeIndex = content.lastIndexOf('</array>', arrayEnd);
    if (closeIndex < 0) {
      return;
    }
    final block =
        '''
    <dict>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>$scheme</string>
      </array>
    </dict>
''';
    content = content.replaceRange(closeIndex, closeIndex, block);
    files.write(path, content);
  }

  @override
  void revert(ProjectFiles files) {
    var content = files.read(path);
    if (content == null) {
      return;
    }
    final keyTag = '<key>CFBundleURLTypes</key>';
    final keyIndex = content.indexOf(keyTag);
    if (keyIndex < 0) {
      return;
    }
    final arrayStart = _skipWhitespace(content, keyIndex + keyTag.length);
    final arrayEnd = elementEnd(content, arrayStart);
    final arrayContent = content.substring(arrayStart, arrayEnd);
    final schemeTag = '<string>$scheme</string>';
    final schemeIndex = arrayContent.indexOf(schemeTag);
    if (schemeIndex < 0) {
      return;
    }

    final dictStart = arrayContent.lastIndexOf('<dict>', schemeIndex);
    if (dictStart >= 0) {
      final dictEnd = elementEnd(arrayContent, dictStart);
      final dict = arrayContent.substring(dictStart, dictEnd);
      final schemesKey = dict.indexOf('<key>CFBundleURLSchemes</key>');
      final hasOtherSchemes =
          schemesKey >= 0 &&
          dict
              .substring(schemesKey)
              .replaceAll(schemeTag, '')
              .contains('<string>');
      if (!hasOtherSchemes) {
        var start = arrayStart + dictStart;
        final end = arrayStart + dictEnd;
        while (start > arrayStart && content[start - 1].trim().isEmpty) {
          start--;
        }
        content = content.replaceRange(start, end, '');
        final remainingKeyIndex = content.indexOf(keyTag);
        if (remainingKeyIndex >= 0) {
          final remainingStart = _skipWhitespace(
            content,
            remainingKeyIndex + keyTag.length,
          );
          final remainingEnd = elementEnd(content, remainingStart);
          if (!content
              .substring(remainingStart, remainingEnd)
              .contains('<dict')) {
            content = removePlistEntry(content, 'CFBundleURLTypes');
          }
        }
        files.write(path, content);
        return;
      }
    }

    final absolute = arrayStart + schemeIndex;
    content = content.replaceRange(absolute, absolute + schemeTag.length, '');
    files.write(path, content);
  }
}

int _skipWhitespace(String content, int index) {
  var cursor = index;
  while (cursor < content.length && content[cursor].trim().isEmpty) {
    cursor++;
  }
  return cursor;
}

/// Adds a custom URL scheme to iOS.
final class IosUrlSchemePatch extends PlistUrlSchemePatch {
  const IosUrlSchemePatch(String scheme)
    : super(
        path: kIosInfoPlistPath,
        platform: 'ios',
        platformName: 'iOS',
        scheme: scheme,
      );
}

/// Adds a custom URL scheme to macOS.
final class MacosUrlSchemePatch extends PlistUrlSchemePatch {
  const MacosUrlSchemePatch(String scheme)
    : super(
        path: kMacosInfoPlistPath,
        platform: 'macos',
        platformName: 'macOS',
        scheme: scheme,
      );
}
