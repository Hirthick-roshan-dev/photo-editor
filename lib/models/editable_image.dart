import 'dart:typed_data';
import 'dart:ui' as ui;

class EditableImage {
  final Uint8List bytes;
  final String name;
  final String? path;
  final int? fileSizeInBytes;
  final int? width;
  final int? height;

  const EditableImage({
    required this.bytes,
    required this.name,
    this.path,
    this.fileSizeInBytes,
    this.width,
    this.height,
  });

  String get formattedSize {
    final size = fileSizeInBytes ?? bytes.lengthInBytes;
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  String get resolution {
    if (width != null && height != null) {
      return '${width}x$height';
    }
    return '';
  }

  static Future<EditableImage> fromBytes({
    required Uint8List bytes,
    required String name,
    String? path,
    int? size,
  }) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      return EditableImage(
        bytes: bytes,
        name: name,
        path: path,
        fileSizeInBytes: size ?? bytes.lengthInBytes,
        width: image.width,
        height: image.height,
      );
    } catch (_) {
      return EditableImage(
        bytes: bytes,
        name: name,
        path: path,
        fileSizeInBytes: size ?? bytes.lengthInBytes,
      );
    }
  }
}
