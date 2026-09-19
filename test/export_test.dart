import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_editor/models/editable_image.dart';
import 'package:photo_editor/utils/export_engine.dart';
import 'package:photo_editor/widgets/export_dialog.dart';

void main() {
  late EditableImage testImage;

  setUp(() {
    // Generate a simple test image
    final img.Image image = img.Image(width: 100, height: 100);
    img.fill(image, color: img.ColorRgba8(255, 0, 0, 255));
    final Uint8List bytes = Uint8List.fromList(img.encodePng(image));

    testImage = EditableImage(
      bytes: bytes,
      name: 'test_photo.png',
      fileSizeInBytes: bytes.lengthInBytes,
      width: 100,
      height: 100,
    );
  });

  group('ExportEngine Tests', () {
    test('processImage exports PNG format successfully', () async {
      final result = await ExportEngine.processImage(
        image: testImage,
        format: ExportFormat.png,
        quality: 0.9,
        scale: 1.0,
      );

      expect(result.format, ExportFormat.png);
      expect(result.fileName.endsWith('.png'), isTrue);
      expect(result.width, 100);
      expect(result.height, 100);
      expect(result.bytes.isNotEmpty, isTrue);
    });

    test('processImage exports JPEG format with quality and scaling', () async {
      final result = await ExportEngine.processImage(
        image: testImage,
        format: ExportFormat.jpeg,
        quality: 0.8,
        scale: 0.5,
      );

      expect(result.format, ExportFormat.jpeg);
      expect(result.fileName.endsWith('.jpg'), isTrue);
      expect(result.width, 50);
      expect(result.height, 50);
      expect(result.bytes.isNotEmpty, isTrue);
    });

    test('processImage exports BMP format successfully', () async {
      final result = await ExportEngine.processImage(
        image: testImage,
        format: ExportFormat.bmp,
        quality: 1.0,
        scale: 1.0,
      );

      expect(result.format, ExportFormat.bmp);
      expect(result.fileName.endsWith('.bmp'), isTrue);
      expect(result.bytes.isNotEmpty, isTrue);
    });
  });

  group('ExportDialog Widget Tests', () {
    testWidgets('Renders ExportDialog and toggles formats', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ExportDialog.show(context, testImage),
                child: const Text('Open Export'),
              ),
            ),
          ),
        ),
      );

      // Tap to open ExportDialog
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      // Verify header and controls
      expect(find.text('Export & Save Photo'), findsOneWidget);
      expect(find.text('PNG'), findsOneWidget);
      expect(find.text('JPEG'), findsOneWidget);
      expect(find.text('BMP'), findsOneWidget);
      expect(find.text('Save to Device'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);

      // Select JPEG
      await tester.tap(find.text('JPEG'));
      await tester.pumpAndSettle();

      // Verify Quality Slider appears for JPEG
      expect(find.text('Quality Compression'), findsOneWidget);

      // Select 50% scale
      await tester.tap(find.text('50%'));
      await tester.pumpAndSettle();

      expect(find.text('50x50 px'), findsOneWidget);
    });
  });
}
