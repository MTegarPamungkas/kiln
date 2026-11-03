import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

/// Bottom sheet that lets the user choose the camera or the gallery.
final class ImageSourceSheet {
  const ImageSourceSheet._();

  static Future<MediaSource?> show(BuildContext context) {
    return showModalBottomSheet<MediaSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(context).pop(MediaSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () => Navigator.of(context).pop(MediaSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
