import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';
import '../models/editable_image.dart';

class ImageDrawApplier {
  /// Bakes the list of [DrawingStroke]s directly onto the original [EditableImage]
  /// at its native full resolution, maintaining pixel-perfect coordinate alignment.
  static Future<EditableImage> applyDrawings({
    required EditableImage image,
    required List<DrawingStroke> strokes,
  }) async {
    if (strokes.isEmpty) {
      return image;
    }

    final ui.Codec codec = await ui.instantiateImageCodec(image.bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image srcImage = frame.image;

    final int outW = srcImage.width;
    final int outH = srcImage.height;
    final Size targetSize = Size(outW.toDouble(), outH.toDouble());

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, targetSize.width, targetSize.height));

    // 1. Draw base photo
    final Paint basePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;
    canvas.drawImage(srcImage, Offset.zero, basePaint);

    // 2. Draw strokes on an isolated layer so BlendMode.clear (eraser) only erases strokes
    final Rect canvasBounds = Rect.fromLTWH(0, 0, targetSize.width, targetSize.height);
    canvas.saveLayer(canvasBounds, Paint());

    for (final stroke in strokes) {
      stroke.renderToCanvas(canvas, targetSize);
    }

    canvas.restore();

    // 3. Rasterize and encode to PNG
    final ui.Picture picture = recorder.endRecording();
    final ui.Image drawnUiImage = await picture.toImage(outW, outH);
    final ByteData? byteData = await drawnUiImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('Failed to encode drawn image data');
    }

    final Uint8List drawnBytes = byteData.buffer.asUint8List();

    // Generate output filename
    String baseName = image.name;
    final dotIndex = baseName.lastIndexOf('.');
    if (dotIndex != -1) {
      baseName = '${baseName.substring(0, dotIndex)}_drawn.png';
    } else {
      baseName = '${baseName}_drawn.png';
    }

    return EditableImage(
      bytes: drawnBytes,
      name: baseName,
      path: image.path,
      fileSizeInBytes: drawnBytes.lengthInBytes,
      width: outW,
      height: outH,
    );
  }
}
