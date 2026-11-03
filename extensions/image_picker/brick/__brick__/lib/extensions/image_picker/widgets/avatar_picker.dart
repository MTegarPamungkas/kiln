import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import '../picked_image_x.dart';
import 'image_source_sheet.dart';

/// A circular avatar that opens the picker when tapped.
final class AvatarPicker extends StatefulWidget {
  const AvatarPicker({
    super.key,
    required this.picker,
    this.initialImage,
    this.onPicked,
    this.radius = 40,
    this.maxWidth = 512,
    this.maxHeight = 512,
    this.imageQuality = 85,
  });

  final MediaPicker picker;
  final PickedImage? initialImage;
  final ValueChanged<PickedImage>? onPicked;
  final double radius;
  final int maxWidth;
  final int maxHeight;
  final int imageQuality;

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

final class _AvatarPickerState extends State<AvatarPicker> {
  PickedImage? _image;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
  }

  Future<void> _pick() async {
    if (_busy) {
      return;
    }
    final source = await ImageSourceSheet.show(context);
    if (source == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final picked = await widget.picker.pickImage(
        source: source,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
        imageQuality: widget.imageQuality,
      );
      if (!mounted || picked == null) {
        return;
      }
      setState(() => _image = picked);
      widget.onPicked?.call(picked);
    } on Failure catch (failure) {
      if (!mounted) {
        return;
      }
      final message = failure.isPermissionFailure
          ? 'Izin kamera atau galeri ditolak.'
          : failure.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Semantics(
      button: true,
      label: 'Ganti foto profil',
      child: InkWell(
        onTap: _busy ? null : _pick,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            CircleAvatar(
              radius: widget.radius,
              backgroundImage: image?.toImageProvider(),
              child: image == null
                  ? Icon(
                      Icons.person_outline,
                      size: widget.radius,
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: widget.radius * 0.32,
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: widget.radius * 0.32,
                ),
              ),
            ),
            if (_busy)
              Positioned.fill(
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: SizedBox(
                    width: widget.radius * 0.6,
                    height: widget.radius * 0.6,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
