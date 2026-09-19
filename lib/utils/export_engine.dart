import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/editable_image.dart';

enum ExportFormat {
  png,
  jpeg,
  bmp,
}

extension ExportFormatExtension on ExportFormat {
  String get extensionName {
    switch (this) {
      case ExportFormat.png:
        return 'png';
      case ExportFormat.jpeg:
        return 'jpg';
      case ExportFormat.bmp:
        return 'bmp';
    }
  }

  String get displayName {
    switch (this) {
      case ExportFormat.png:
        return 'PNG (Lossless)';
      case ExportFormat.jpeg:
        return 'JPEG (Compact)';
      case ExportFormat.bmp:
        return 'BMP (High Quality)';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.png:
        return 'image/png';
      case ExportFormat.jpeg:
        return 'image/jpeg';
      case ExportFormat.bmp:
        return 'image/bmp';
    }
  }
}

class ExportResult {
  final Uint8List bytes;
  final String fileName;
  final ExportFormat format;
  final int width;
  final int height;
  final int fileSizeBytes;
  final String? savedPath;

  const ExportResult({
    required this.bytes,
    required this.fileName,
    required this.format,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    this.savedPath,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  String get resolution => '${width}x$height';
}

class ExportEngine {
  /// Processes the image with format conversion, quality compression, and scaling.
  static Future<ExportResult> processImage({
    required EditableImage image,
    required ExportFormat format,
    required double quality, // 0.1 to 1.0
    required double scale, // 0.25 to 1.0
    String? customFileName,
  }) async {
    final img.Image? decoded = img.decodeImage(image.bytes);
    if (decoded == null) {
      throw Exception('Failed to decode source image bytes');
    }

    img.Image processed = decoded;

    // Apply scaling if requested
    if (scale < 0.999) {
      final int targetW = (decoded.width * scale).round().clamp(1, 16384);
      final int targetH = (decoded.height * scale).round().clamp(1, 16384);
      processed = img.copyResize(
        decoded,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.cubic,
      );
    }

    final int qualityInt = (quality * 100).round().clamp(1, 100);
    final Uint8List encodedBytes;

    switch (format) {
      case ExportFormat.png:
        final int level = ((1.0 - quality) * 9).round().clamp(0, 9);
        encodedBytes = Uint8List.fromList(img.encodePng(processed, level: level));
        break;
      case ExportFormat.jpeg:
        encodedBytes = Uint8List.fromList(img.encodeJpg(processed, quality: qualityInt));
        break;
      case ExportFormat.bmp:
        encodedBytes = Uint8List.fromList(img.encodeBmp(processed));
        break;
    }

    // Generate output file name
    String baseName = customFileName?.trim().isNotEmpty == true
        ? customFileName!.trim()
        : image.name;

    final int dotIndex = baseName.lastIndexOf('.');
    if (dotIndex != -1) {
      baseName = baseName.substring(0, dotIndex);
    }
    if (!baseName.toLowerCase().endsWith('_edited')) {
      baseName = '${baseName}_edited';
    }
    final String finalFileName = '$baseName.${format.extensionName}';

    return ExportResult(
      bytes: encodedBytes,
      fileName: finalFileName,
      format: format,
      width: processed.width,
      height: processed.height,
      fileSizeBytes: encodedBytes.lengthInBytes,
    );
  }

  /// Saves the exported image bytes to device storage (Pictures / Downloads / Documents directory).
  static Future<String> saveToStorage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    Directory? targetDir;

    try {
      if (Platform.isAndroid) {
        // Prefer external storage Pictures or Downloads directory on Android
        final List<Directory>? extDirs = await getExternalStorageDirectories(type: StorageDirectory.pictures);
        if (extDirs != null && extDirs.isNotEmpty) {
          targetDir = extDirs.first;
        } else {
          targetDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        targetDir = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isLinux) {
        targetDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      // Fallback
      targetDir = await getApplicationDocumentsDirectory();
    }

    targetDir ??= await getApplicationDocumentsDirectory();

    // Ensure directory exists
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // Build unique file path if file already exists
    String filePath = '${targetDir.path}/$fileName';
    File file = File(filePath);

    if (await file.exists()) {
      final int dotIndex = fileName.lastIndexOf('.');
      final String nameWithoutExt = dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
      final String ext = dotIndex != -1 ? fileName.substring(dotIndex) : '';
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      filePath = '${targetDir.path}/${nameWithoutExt}_$timestamp$ext';
      file = File(filePath);
    }

    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Shares the image via native system share sheet.
  static Future<void> shareImage({
    required Uint8List bytes,
    required String fileName,
    String? subject,
  }) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String tempFilePath = '${tempDir.path}/$fileName';
    final File tempFile = File(tempFilePath);

    await tempFile.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFilePath, name: fileName)],
        subject: subject ?? 'Edited Photo: $fileName',
      ),
    );
  }
}
