import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

/// Explains why a permission is needed before the system prompt appears.
class PermissionRationaleDialog extends StatelessWidget {
  const PermissionRationaleDialog({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PermissionRationaleDialog(
        title: title,
        message: message,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Nanti'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Lanjutkan'),
        ),
      ],
    );
  }
}

/// Offers to open the settings page after a permanent denial.
class OpenSettingsDialog extends StatelessWidget {
  const OpenSettingsDialog({required this.permissions, super.key});

  final Permissions permissions;

  static Future<bool> show(
    BuildContext context, {
    required Permissions permissions,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => OpenSettingsDialog(permissions: permissions),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Izin dinonaktifkan'),
      content: const Text(
        'Aktifkan izin ini dari pengaturan aplikasi untuk melanjutkan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Tutup'),
        ),
        FilledButton(
          onPressed: () async {
            await permissions.openSettings();
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Buka pengaturan'),
        ),
      ],
    );
  }
}
