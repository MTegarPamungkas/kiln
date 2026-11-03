import 'patch.dart';

const String kWebIndexPath = 'web/index.html';

/// Marks the web runner as containing a Kiln extension.
final class WebIndexMetaPatch implements Patch {
  const WebIndexMetaPatch(this.extensionId);

  final String extensionId;

  @override
  String get id => 'web.index.$extensionId';

  @override
  String get description => 'Add Kiln marker to web/index.html';

  @override
  void apply(ProjectFiles files) {
    final content = files.read(kWebIndexPath);
    if (content == null ||
        content.contains('name="kiln-extension:$extensionId"')) {
      return;
    }
    final line =
        '  <meta name="kiln-extension:$extensionId" content="installed"/>\n';
    files.write(kWebIndexPath, content.replaceFirst('</head>', '$line</head>'));
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kWebIndexPath);
    if (content == null) {
      return;
    }
    files.write(
      kWebIndexPath,
      content.replaceAll(
        RegExp(
          r'\s*<meta name="kiln-extension:' +
              RegExp.escape(extensionId) +
              r'" content="installed"\s*/>',
        ),
        '',
      ),
    );
  }
}
