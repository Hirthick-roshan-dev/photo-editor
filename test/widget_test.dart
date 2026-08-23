import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor/main.dart';
import 'package:photo_editor/screens/crop_screen.dart';
import 'package:photo_editor/screens/edit_screen.dart';
import 'package:photo_editor/screens/filter_screen.dart';
import 'package:photo_editor/widgets/crop_overlay.dart';

void main() {
  testWidgets('PhotoEditorApp smoke test - renders HomeScreen, EditScreen, CropScreen and FilterScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotoEditorApp());
    await tester.pump();

    // Verify HomeScreen renders title and action buttons
    expect(find.text('Photo Editor'), findsOneWidget);
    expect(find.text('Select an Image to Edit'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Sample'), findsOneWidget);

    // Tap on the Sample button to trigger sample image generation and navigation
    await tester.tap(find.text('Sample'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify EditScreen is displayed
    expect(find.byType(EditScreen), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Adjust'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Crop'), findsOneWidget);

    // Tap on the Crop tool
    await tester.tap(find.text('Crop'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify dedicated CropScreen is displayed with CropOverlay and light themed controls
    expect(find.byType(CropScreen), findsOneWidget);
    expect(find.byType(CropOverlay), findsOneWidget);
    expect(find.text('Crop'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);

    // Apply crop
    await tester.tap(find.text('Apply'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify returning to EditScreen
    expect(find.byType(CropScreen), findsNothing);
    expect(find.byType(EditScreen), findsOneWidget);

    // Tap on the Filters tool
    await tester.tap(find.text('Filters'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify FilterScreen is displayed
    expect(find.byType(FilterScreen), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Vivid'), findsOneWidget);

    // Tap Apply
    await tester.tap(find.text('Apply'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify returning to EditScreen
    expect(find.byType(FilterScreen), findsNothing);
    expect(find.byType(EditScreen), findsOneWidget);
  });
}
