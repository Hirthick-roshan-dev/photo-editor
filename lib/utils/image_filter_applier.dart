import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/editable_image.dart';

class ImageFilterApplier {
  /// Applies a 4x5 color matrix filter to an [EditableImage] and produces a new rasterized image.
  static Future<EditableImage> applyFilter({
    required EditableImage image,
    required List<double> matrix,
    String? filterName,
  }) async {
    final ui.Codec codec = await ui.instantiateImageCodec(image.bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image srcImage = frame.image;

    final int outW = srcImage.width;
    final int outH = srcImage.height;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
    );

    final Paint paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high
      ..colorFilter = ColorFilter.matrix(matrix);

    canvas.drawImage(srcImage, Offset.zero, paint);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image filteredUiImage = await picture.toImage(outW, outH);
    final ByteData? byteData = await filteredUiImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('Failed to encode filtered image data');
    }

    final Uint8List filteredBytes = byteData.buffer.asUint8List();

    // Create updated file name
    String baseName = image.name;
    final String tag = filterName != null
        ? '_${filterName.toLowerCase().replaceAll(' ', '_')}'
        : '_filtered';

    final dotIndex = baseName.lastIndexOf('.');
    if (dotIndex != -1) {
      baseName = '${baseName.substring(0, dotIndex)}$tag.png';
    } else {
      baseName = '$baseName$tag.png';
    }

    return EditableImage(
      bytes: filteredBytes,
      name: baseName,
      path: image.path,
      fileSizeInBytes: filteredBytes.lengthInBytes,
      width: outW,
      height: outH,
    );
  }
}
