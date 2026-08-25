import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor/models/editable_image.dart';
import 'package:photo_editor/models/text_layer.dart';
import 'package:photo_editor/screens/text_screen.dart';
import 'package:photo_editor/utils/image_text_applier.dart';

Future<EditableImage> _createTestImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 200, 200));
  final paint = Paint()..color = const Color(0xFF3B82F6);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 200), paint);
  final picture = recorder.endRecording();
  final img = await picture.toImage(200, 200);
  final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List bytes = byteData!.buffer.asUint8List();

  return EditableImage(
    bytes: bytes,
    name: 'sample_photo.png',
    fileSizeInBytes: bytes.lengthInBytes,
    width: 200,
    height: 200,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TextLayer Model & Presets Tests', () {
    test('Typography presets list is populated', () {
      expect(TextFontPreset.presets.isNotEmpty, isTrue);
      expect(TextFontPreset.presets.any((p) => p.id == 'modern'), isTrue);
      expect(TextFontPreset.presets.any((p) => p.id == 'bold_impact'), isTrue);
      expect(TextFontPreset.presets.any((p) => p.id == 'elegant'), isTrue);
    });

    test('TextLayer copyWith and properties work correctly', () {
      const layer = TextLayer(
        id: 'test_1',
        text: 'Hello World',
        position: Offset(100, 100),
        canvasSize: Size(200, 200),
      );

      expect(layer.displayText, equals('Hello World'));

      final uppercaseLayer = layer.copyWith(isUppercase: true);
      expect(uppercaseLayer.displayText, equals('HELLO WORLD'));

      final movedLayer = layer.copyWith(position: const Offset(150, 120), fontSize: 40);
      expect(movedLayer.position, equals(const Offset(150, 120)));
      expect(movedLayer.fontSize, equals(40));
    });

    test('TextLayer measureSize returns positive size', () {
      const layer = TextLayer(
        id: 'test_2',
        text: 'Testing Dimensions',
        position: Offset(100, 100),
        canvasSize: Size(200, 200),
        fontSize: 24,
      );

      final size = layer.measureSize();
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('TextLayer renders onto canvas without errors', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 200, 200));

      const layer = TextLayer(
        id: 'test_3',
        text: 'Canvas Render',
        position: Offset(100, 100),
        canvasSize: Size(200, 200),
        backgroundStyle: TextBackgroundStyle.filledBox,
        hasStroke: true,
        hasShadow: true,
      );

      // Render full canvas and local box
      layer.renderToCanvas(canvas, const Size(200, 200));
      layer.renderLocalBox(canvas, const Size(100, 50));

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('ImageTextApplier Utility Tests', () {
    test('applyTextLayers bakes text and returns updated EditableImage', () async {
      final testImg = await _createTestImage();
      final layers = [
        const TextLayer(
          id: 'layer_1',
          text: 'Overlay Text',
          position: Offset(100, 100),
          canvasSize: Size(200, 200),
          fontSize: 24,
          color: Colors.white,
        ),
      ];

      final result = await ImageTextApplier.applyTextLayers(
        image: testImg,
        layers: layers,
      );

      expect(result.bytes.isNotEmpty, isTrue);
      expect(result.width, equals(200));
      expect(result.height, equals(200));
      expect(result.name, contains('_text.png'));
    });

    test('applyTextLayers returns original image if layers list is empty', () async {
      final testImg = await _createTestImage();
      final result = await ImageTextApplier.applyTextLayers(
        image: testImg,
        layers: [],
      );

      expect(result, equals(testImg));
    });
  });

  group('TextScreen Widget Tests', () {
    testWidgets('TextScreen renders canvas, header, bottom tabs, and supports adding text', (WidgetTester tester) async {
      final testImg = await _createTestImage();

      await tester.pumpWidget(
        MaterialApp(
          home: TextScreen(image: testImg),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and controls
      expect(find.text('Add Text'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Text & Font'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Badge'), findsOneWidget);
      expect(find.text('Effects'), findsOneWidget);
      expect(find.text('Layers'), findsOneWidget);

      // Verify default text is present
      expect(find.text('Add Text Here'), findsWidgets);

      // Switch to Color tab
      await tester.tap(find.text('Color'));
      await tester.pumpAndSettle();
      expect(find.text('Opacity'), findsOneWidget);

      // Switch to Badge tab
      await tester.tap(find.text('Badge'));
      await tester.pumpAndSettle();
      expect(find.text('Box'), findsOneWidget);
      expect(find.text('Badge'), findsWidgets);

      // Switch to Effects tab
      await tester.tap(find.text('Effects'));
      await tester.pumpAndSettle();
      expect(find.text('Outline Stroke'), findsOneWidget);
      expect(find.text('Drop Shadow'), findsOneWidget);

      // Switch to Layers tab
      await tester.tap(find.text('Layers'));
      await tester.pumpAndSettle();
      expect(find.text('1 Total Layers'), findsOneWidget);

      // Tap Apply to bake and close
      await tester.tap(find.text('Apply'));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
