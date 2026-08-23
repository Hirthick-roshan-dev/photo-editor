import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor/models/editable_image.dart';
import 'package:photo_editor/models/filter_preset.dart';
import 'package:photo_editor/screens/edit_screen.dart';
import 'package:photo_editor/screens/filter_screen.dart';
import 'package:photo_editor/utils/image_filter_applier.dart';

Future<EditableImage> _createTestImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 100, 100));
  final paint = Paint()..color = const Color(0xFFFF5500);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);
  final picture = recorder.endRecording();
  final img = await picture.toImage(100, 100);
  final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List bytes = byteData!.buffer.asUint8List();

  return EditableImage(
    bytes: bytes,
    name: 'test_photo.png',
    fileSizeInBytes: bytes.lengthInBytes,
    width: 100,
    height: 100,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FilterPreset Model Tests', () {
    test('Preset list contains key filters', () {
      expect(FilterPreset.presets.isNotEmpty, isTrue);
      expect(FilterPreset.presets.any((p) => p.id == 'original'), isTrue);
      expect(FilterPreset.presets.any((p) => p.id == 'vivid'), isTrue);
      expect(FilterPreset.presets.any((p) => p.id == 'warm'), isTrue);
      expect(FilterPreset.presets.any((p) => p.id == 'mono'), isTrue);
      expect(FilterPreset.presets.any((p) => p.id == 'sepia'), isTrue);
      expect(FilterPreset.presets.any((p) => p.id == 'cinematic'), isTrue);
    });

    test('Matrix interpolation returns identity at 0.0 and full matrix at 1.0', () {
      final preset = FilterPreset.presets.firstWhere((p) => p.id == 'sepia');
      final zeroMatrix = preset.getAdjustedMatrix(0.0);
      expect(zeroMatrix, equals(FilterPreset.identityMatrix));

      final fullMatrix = preset.getAdjustedMatrix(1.0);
      expect(fullMatrix, equals(preset.matrix));

      final halfMatrix = preset.getAdjustedMatrix(0.5);
      expect(halfMatrix.length, 20);
      expect(
        halfMatrix[0],
        closeTo(
          FilterPreset.identityMatrix[0] * 0.5 + preset.matrix[0] * 0.5,
          0.001,
        ),
      );
    });
  });

  group('ImageFilterApplier Tests', () {
    test('applyFilter produces a valid non-empty EditableImage', () async {
      final testImg = await _createTestImage();
      final preset = FilterPreset.presets.firstWhere((p) => p.id == 'vivid');

      final filtered = await ImageFilterApplier.applyFilter(
        image: testImg,
        matrix: preset.matrix,
        filterName: preset.name,
      );

      expect(filtered.bytes.isNotEmpty, isTrue);
      expect(filtered.width, equals(100));
      expect(filtered.height, equals(100));
      expect(filtered.name, contains('vivid'));
    });
  });

  group('FilterScreen Widget Tests', () {
    testWidgets('FilterScreen renders canvas, presets, and category chips', (WidgetTester tester) async {
      final testImg = await _createTestImage();

      await tester.pumpWidget(
        MaterialApp(
          home: FilterScreen(image: testImg),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify title & app bar
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      // Verify presets are displayed
      expect(find.text('Original'), findsWidgets);
      expect(find.text('Vivid'), findsOneWidget);

      // Verify Category Chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Vintage'), findsOneWidget);
      expect(find.text('B&W'), findsOneWidget);

      // Tap on a filter (Vivid)
      await tester.tap(find.text('Vivid'));
      await tester.pump(const Duration(milliseconds: 100));

      // Intensity slider should now be visible
      expect(find.text('Intensity'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Compare button should be present when filter is active
      expect(find.text('Compare'), findsOneWidget);

      // Reset button in AppBar
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('EditScreen navigates to FilterScreen and applies filter', (WidgetTester tester) async {
      final testImg = await _createTestImage();

      await tester.pumpWidget(
        MaterialApp(
          home: EditScreen(image: testImg),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Filters tool
      expect(find.text('Filters'), findsOneWidget);
      await tester.tap(find.text('Filters'));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify FilterScreen is now displayed
      expect(find.byType(FilterScreen), findsOneWidget);

      // Select 'Warm'
      await tester.tap(find.text('Warm'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify back on EditScreen
      expect(find.byType(FilterScreen), findsNothing);
      expect(find.byType(EditScreen), findsOneWidget);
    });
  });
}
