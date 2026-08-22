import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/editable_image.dart';

class ImageCropper {
  /// Crops an image represented by [EditableImage] using normalized coordinates (0.0 to 1.0)
  /// and applies any rotation (in degrees: 0, 90, 180, 270) and flips.
  static Future<EditableImage> cropImage({
    required EditableImage image,
    required Rect normalizedCropRect,
    int rotationDegrees = 0,
    bool flipHorizontal = false,
    bool flipVertical = false,
  }) async {
    final ui.Codec codec = await ui.instantiateImageCodec(image.bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image srcImage = frame.image;

    final double imgW = srcImage.width.toDouble();
    final double imgH = srcImage.height.toDouble();

    // Calculate source crop rect in original image pixel coordinates
    final double cropLeft = (normalizedCropRect.left * imgW).clamp(0.0, imgW);
    final double cropTop = (normalizedCropRect.top * imgH).clamp(0.0, imgH);
    final double cropWidth = (normalizedCropRect.width * imgW).clamp(1.0, imgW - cropLeft);
    final double cropHeight = (normalizedCropRect.height * imgH).clamp(1.0, imgH - cropTop);

    final Rect srcRect = Rect.fromLTWH(cropLeft, cropTop, cropWidth, cropHeight);

    // Determine target dimensions considering rotation
    final bool isRotated90or270 = rotationDegrees == 90 || rotationDegrees == 270;
    final int outW = (isRotated90or270 ? cropHeight : cropWidth).round().clamp(1, 16384);
    final int outH = (isRotated90or270 ? cropWidth : cropHeight).round().clamp(1, 16384);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()));

    // Apply center transformations for rotation & flip
    canvas.save();
    canvas.translate(outW / 2.0, outH / 2.0);

    if (flipHorizontal) {
      canvas.scale(-1.0, 1.0);
    }
    if (flipVertical) {
      canvas.scale(1.0, -1.0);
    }
    if (rotationDegrees != 0) {
      canvas.rotate(rotationDegrees * 3.1415926535897932 / 180.0);
    }

    final Rect dstRect = Rect.fromCenter(
      center: Offset.zero,
      width: cropWidth,
      height: cropHeight,
    );

    final Paint paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;

    canvas.drawImageRect(srcImage, srcRect, dstRect, paint);
    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    final ui.Image croppedUiImage = await picture.toImage(outW, outH);
    final ByteData? byteData = await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to encode cropped image data');
    }

    final Uint8List croppedBytes = byteData.buffer.asUint8List();

    // Create updated file name
    String baseName = image.name;
    final dotIndex = baseName.lastIndexOf('.');
    if (dotIndex != -1) {
      baseName = '${baseName.substring(0, dotIndex)}_cropped.png';
    } else {
      baseName = '${baseName}_cropped.png';
    }

    return EditableImage(
      bytes: croppedBytes,
      name: baseName,
      path: image.path,
      fileSizeInBytes: croppedBytes.lengthInBytes,
      width: outW,
      height: outH,
    );
  }
}
