import 'dart:io';

import 'package:crypto/crypto.dart';

/// Hashes files so `remove` and `doctor` can detect user edits.
final class FileOwnership {
  const FileOwnership();

  String hashBytes(List<int> bytes) => 'sha256:${sha256.convert(bytes)}';

  String hashFile(File file) => hashBytes(file.readAsBytesSync());

  bool hasChanged({required File file, required String? ownedHash}) {
    if (!file.existsSync()) {
      return true;
    }
    if (ownedHash == null || ownedHash.isEmpty) {
      return true;
    }
    return hashFile(file) != ownedHash;
  }
}
