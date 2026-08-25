import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/editable_image.dart';
import '../models/text_layer.dart';

class ImageTextApplier {
  /// Bakes the list of [TextLayer]s directly onto the original [EditableImage]
  /// at its native full resolution, maintaining pixel-perfect typography, scaling, and transforms.
  static Future<EditableImage> applyTextLayers({
    required EditableImage image,
    required List<TextLayer> layers,
  }) async {
    if (layers.isEmpty) {
      return image;
    }

    final ui.Codec codec = await ui.instantiateImageCodec(image.bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image srcImage = frame.image;

    final int outW = srcImage.width;
    final int outH = srcImage.height;
    final Size targetSize = Size(outW.toDouble(), outH.toDouble());

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, targetSize.width, targetSize.height),
    );

    // 1. Draw base photo at native resolution
    final Paint basePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;
    canvas.drawImage(srcImage, Offset.zero, basePaint);

    // 2. Draw all text layers in order
    for (final layer in layers) {
      layer.renderToCanvas(canvas, targetSize);
    }

    // 3. Rasterize and encode to PNG
    final ui.Picture picture = recorder.endRecording();
    final ui.Image textUiImage = await picture.toImage(outW, outH);
    final ByteData? byteData = await textUiImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('Failed to encode text-rendered image data');
    }

    final Uint8List textBytes = byteData.buffer.asUint8List();

    // Generate output filename
    String baseName = image.name;
    final dotIndex = baseName.lastIndexOf('.');
    if (dotIndex != -1) {
      baseName = '${baseName.substring(0, dotIndex)}_text.png';
    } else {
      baseName = '${baseName}_text.png';
    }

    return EditableImage(
      bytes: textBytes,
      name: baseName,
      path: image.path,
      fileSizeInBytes: textBytes.lengthInBytes,
      width: outW,
      height: outH,
    );
  }
}
