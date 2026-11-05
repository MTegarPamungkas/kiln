import 'dart:io';

/// File system operations used by commands, replaceable in tests.
abstract interface class FileSystem {
  bool exists(String path);

  bool fileExists(String path);

  bool directoryExists(String path);

  String readAsString(String path);

  List<int> readAsBytes(String path);

  void writeAsString(String path, String content);

  void writeAsBytes(String path, List<int> bytes);

  void createDirectory(String path, {bool recursive = true});

  void delete(String path, {bool recursive = true});

  Directory createTemp(String prefix);

  List<FileSystemEntity> list(String path, {bool recursive = false});
}

/// [FileSystem] backed by dart:io.
final class LocalFileSystem implements FileSystem {
  const LocalFileSystem();

  @override
  bool exists(String path) =>
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

  @override
  bool fileExists(String path) => File(path).existsSync();

  @override
  bool directoryExists(String path) => Directory(path).existsSync();

  @override
  String readAsString(String path) => File(path).readAsStringSync();

  @override
  List<int> readAsBytes(String path) => File(path).readAsBytesSync();

  @override
  void writeAsString(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  @override
  void writeAsBytes(String path, List<int> bytes) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  }

  @override
  void createDirectory(String path, {bool recursive = true}) {
    Directory(path).createSync(recursive: recursive);
  }

  @override
  void delete(String path, {bool recursive = true}) {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.notFound) {
      return;
    }
    if (type == FileSystemEntityType.directory) {
      Directory(path).deleteSync(recursive: recursive);
    } else {
      File(path).deleteSync();
    }
  }

  @override
  Directory createTemp(String prefix) =>
      Directory.systemTemp.createTempSync(prefix);

  @override
  List<FileSystemEntity> list(String path, {bool recursive = false}) {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      return const <FileSystemEntity>[];
    }
    return directory.listSync(recursive: recursive);
  }
}
