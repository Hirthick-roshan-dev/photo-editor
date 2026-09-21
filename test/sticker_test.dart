import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor/models/editable_image.dart';
import 'package:photo_editor/models/sticker_layer.dart';
import 'package:photo_editor/screens/stickers_screen.dart';
import 'package:photo_editor/utils/image_sticker_applier.dart';

Future<EditableImage> _createTestImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 200, 200));
  final paint = Paint()..color = const Color(0xFF10B981);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 200), paint);
  final picture = recorder.endRecording();
  final img = await picture.toImage(200, 200);
  final ByteData? byteData =
      await img.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List bytes = byteData!.buffer.asUint8List();

  return EditableImage(
    bytes: bytes,
    name: 'test_sticker_photo.png',
    fileSizeInBytes: bytes.lengthInBytes,
    width: 200,
    height: 200,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sticker Catalog & Category Tests', () {
    test('Categories and Catalog are populated with emojis and badges', () {
      expect(StickerCategory.categories.isNotEmpty, isTrue);
      expect(StickerCatalogItem.catalog.isNotEmpty, isTrue);
      expect(
        StickerCatalogItem.catalog.any((s) => s.categoryId == 'popular'),
        isTrue,
      );
      expect(
        StickerCatalogItem.catalog.any((s) => s.categoryId == 'faces'),
        isTrue,
      );
      expect(
        StickerCatalogItem.catalog.any((s) => s.categoryId == 'badges'),
        isTrue,
      );
    });
  });

  group('StickerLayer Model Tests', () {
    test('StickerLayer copyWith and transforms work correctly', () {
      const layer = StickerLayer(
        id: 'st_1',
        content: '🔥',
        position: Offset(100, 100),
        canvasSize: Size(200, 200),
      );

      expect(layer.content, equals('🔥'));
      expect(layer.isFlippedH, isFalse);

      final flipped = layer.copyWith(isFlippedH: true, isFlippedV: true, scale: 2.0);
      expect(flipped.isFlippedH, isTrue);
      expect(flipped.isFlippedV, isTrue);
      expect(flipped.scale, equals(2.0));
    });

    test('StickerLayer renders onto canvas without errors', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 200, 200));

      const emojiLayer = StickerLayer(
        id: 'st_emoji',
        type: StickerType.emoji,
        content: '🎉',
        position: Offset(100, 100),
        canvasSize: Size(200, 200),
        hasShadow: true,
      );

      emojiLayer.renderToCanvas(canvas, const Size(200, 200));
      emojiLayer.renderLocalBox(canvas, const Size(80, 80));

      const badgeLayer = StickerLayer(
        id: 'st_badge',
        type: StickerType.iconBadge,
        content: 'badge_star',
        icon: Icons.star_rounded,
        position: Offset(150, 150),
        canvasSize: Size(200, 200),
      );

      badgeLayer.renderToCanvas(canvas, const Size(200, 200));
      badgeLayer.renderLocalBox(canvas, const Size(80, 80));

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('ImageStickerApplier Tests', () {
    test('applyStickerLayers bakes stickers onto image at native resolution', () async {
      final testImg = await _createTestImage();
      final layers = [
        const StickerLayer(
          id: 'st_bake',
          content: '🚀',
          position: Offset(100, 100),
          canvasSize: Size(200, 200),
        ),
      ];

      final result = await ImageStickerApplier.applyStickerLayers(
        image: testImg,
        layers: layers,
      );

      expect(result.bytes.isNotEmpty, isTrue);
      expect(result.width, equals(200));
      expect(result.height, equals(200));
      expect(result.name, contains('_stickers.png'));
    });

    test('applyStickerLayers returns original image if layers list is empty', () async {
      final testImg = await _createTestImage();
      final result = await ImageStickerApplier.applyStickerLayers(
        image: testImg,
        layers: [],
      );

      expect(result, equals(testImg));
    });
  });

  group('StickersScreen Widget Tests', () {
    testWidgets('StickersScreen renders canvas, catalog, transform tabs, and apply flow', (WidgetTester tester) async {
      final testImg = await _createTestImage();

      await tester.pumpWidget(
        MaterialApp(
          home: StickersScreen(image: testImg),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and controls
      expect(find.text('Stickers'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Catalog'), findsOneWidget);
      expect(find.text('Transform'), findsOneWidget);
      expect(find.text('Effects'), findsOneWidget);
      expect(find.text('Layers'), findsOneWidget);

      // Verify initial sticker on canvas
      expect(find.text('🔥'), findsWidgets);

      // Switch to Transform tab
      await tester.tap(find.text('Transform'));
      await tester.pumpAndSettle();
      expect(find.text('Flip H'), findsOneWidget);
      expect(find.text('Flip V'), findsOneWidget);

      // Switch to Effects tab
      await tester.tap(find.text('Effects'));
      await tester.pumpAndSettle();
      expect(find.text('Opacity'), findsOneWidget);
      expect(find.text('Drop Shadow'), findsOneWidget);

      // Switch to Layers tab
      await tester.tap(find.text('Layers'));
      await tester.pumpAndSettle();
      expect(find.text('1 Total Stickers'), findsOneWidget);

      // Switch back to Catalog and add another sticker
      await tester.tap(find.text('Catalog'));
      await tester.pumpAndSettle();
      expect(find.text('Popular'), findsOneWidget);

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
