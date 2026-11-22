/// Local Appwrite settings shared by the setup wizard and doctor.
/// These are public client identifiers, never server API keys.
final class AppwriteSetup {
  const AppwriteSetup(this.answers);

  static const defaults = <String, String>{
    'endpoint': 'https://cloud.appwrite.io/v1',
    'project_id': 'kiln_demo',
    'database_id': 'kiln',
    'bucket_id': 'kiln_files',
  };

  static const labels = <String, String>{
    'endpoint': 'Appwrite API endpoint',
    'project_id': 'Appwrite project ID',
    'database_id': 'Appwrite database ID',
    'bucket_id': 'Appwrite storage bucket ID',
  };

  final Map<String, Object?> answers;

  String? value(String name) {
    final raw = answers[name];
    return raw is String ? raw : null;
  }

  Map<String, String> get issues {
    final result = <String, String>{};
    final endpoint = value('endpoint');
    final uri = endpoint == null ? null : Uri.tryParse(endpoint);
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        RegExp(r'''['"\\$\s]''').hasMatch(endpoint!)) {
      result['endpoint'] = 'Use an absolute HTTP(S) API endpoint without credentials, query, or fragment.';
    }
    for (final name in ['project_id', 'database_id', 'bucket_id']) {
      final identifier = value(name);
      if (identifier == null || identifier.isEmpty) {
        result[name] = '${labels[name]} is required.';
      } else if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(identifier)) {
        result[name] =
            '${labels[name]} must contain only letters, digits, periods, underscores, or hyphens.';
      }
    }
    if (value('project_id') == defaults['project_id']) {
      result['project_id'] =
          'Replace the kiln_demo placeholder with your Appwrite project ID.';
    }
    return result;
  }

  static const nextSteps = <String>[
    'In Appwrite Console, add each app platform with its actual application ID or hostname.',
    'Enable Email/Password authentication before testing sign-in.',
    'For database and file features, create the configured database and bucket and set their permissions.',
    'Enable OAuth providers only if the app uses social sign-in.',
    'Run the app and test sign-in. Server connectivity and console settings have not been checked.',
  ];
}
