import 'package:kiln_core/kiln_core.dart';

/// [MediaPicker] with a programmed result, cancellation, or failure.
final class FakeMediaPicker implements MediaPicker {
  FakeMediaPicker({this.result, this.failure, this.cancelled = false});

  final List<MediaSource> sources = <MediaSource>[];
  PickedImage? result;
  Failure? failure;
  bool cancelled;

  @override
  Future<PickedImage?> pickImage({
    MediaSource source = MediaSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    sources.add(source);
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    if (cancelled) {
      return null;
    }
    return result;
  }
}
