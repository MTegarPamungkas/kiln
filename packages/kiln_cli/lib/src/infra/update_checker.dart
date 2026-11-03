import 'dart:convert';
import 'dart:io';

import '../version.dart';

/// Non-blocking check for a newer CLI release on pub.dev.
final class UpdateChecker {
  const UpdateChecker({this.currentVersion = kilnVersion});

  final String currentVersion;

  Future<String?> check() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('https://pub.dev/api/packages/kiln_cli'),
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }
      final body = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return null;
      }
      final latest = decoded['latest'];
      if (latest is! Map) {
        return null;
      }
      final version = latest['version'];
      if (version is String && version != currentVersion) {
        return version;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
