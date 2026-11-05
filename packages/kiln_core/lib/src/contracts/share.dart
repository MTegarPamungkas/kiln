/// Result of asking the platform share sheet to share content.
enum ShareOutcome { shared, dismissed, unavailable }

/// One file included in a share action.
final class ShareFile {
  const ShareFile({required this.path, this.mimeType, this.name});

  final String path;
  final String? mimeType;
  final String? name;
}

/// Text, subject, and files handed to the platform share sheet.
final class ShareContent {
  const ShareContent({this.text, this.subject, this.files = const <ShareFile>[]});

  final String? text;
  final String? subject;
  final List<ShareFile> files;
}

/// Rectangle used as the iPad popover anchor.
final class ShareOrigin {
  const ShareOrigin({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

/// Opens the platform share sheet.
abstract interface class ShareService {
  Future<ShareOutcome> share(
    ShareContent content, {
    ShareOrigin? origin,
  });
}
