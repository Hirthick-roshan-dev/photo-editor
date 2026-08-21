import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/editable_image.dart';
import 'edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      if (pickedFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      final Uint8List bytes = await pickedFile.readAsBytes();
      final int size = await pickedFile.length();

      final EditableImage editableImage = await EditableImage.fromBytes(
        bytes: bytes,
        name: pickedFile.name.isNotEmpty ? pickedFile.name : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        path: pickedFile.path,
        size: size,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      _navigateToEditScreen(editableImage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent.shade700,
          content: Text('Failed to load image: $e'),
        ),
      );
    }
  }

  Future<void> _loadSampleImage() async {
    try {
      setState(() => _isLoading = true);

      // Generate a vibrant sample canvas image programmatically
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1080, 1080));

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(1080, 1080),
          [
            const Color(0xFF0F172A),
            const Color(0xFF3B82F6),
            const Color(0xFF8B5CF6),
            const Color(0xFFEC4899),
          ],
          [0.0, 0.35, 0.7, 1.0],
        );

      canvas.drawRect(const Rect.fromLTWH(0, 0, 1080, 1080), paint);

      // Draw artistic glowing circles
      final glowPaint1 = Paint()
        ..color = const Color(0xFF06B6D4).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
      canvas.drawCircle(const Offset(350, 400), 220, glowPaint1);

      final glowPaint2 = Paint()
        ..color = const Color(0xFFF43F5E).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 150);
      canvas.drawCircle(const Offset(750, 680), 250, glowPaint2);

      // Draw crisp decorative shapes
      final circlePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.white.withValues(alpha: 0.8);
      canvas.drawCircle(const Offset(540, 540), 200, circlePaint);

      final innerCirclePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(const Offset(540, 540), 12, innerCirclePaint);

      final picture = recorder.endRecording();
      final ui.Image img = await picture.toImage(1080, 1080);
      final ByteData? byteData =
          await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to generate sample image bytes');
      }

      final Uint8List sampleBytes = byteData.buffer.asUint8List();

      final EditableImage editableImage = EditableImage(
        bytes: sampleBytes,
        name: 'sample_creative_artwork.png',
        fileSizeInBytes: sampleBytes.lengthInBytes,
        width: 1080,
        height: 1080,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      _navigateToEditScreen(editableImage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent.shade700,
          content: Text('Failed to create sample image: $e'),
        ),
      );
    }
  }

  void _navigateToEditScreen(EditableImage image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditScreen(image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          // Background ambient gradient orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Badge & Title
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF06B6D4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Photo Studio & Editor',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Main Title
                      const Text(
                        'Create & Edit Stunning Photos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        'Pick an image from your device or camera to begin tuning, cropping, filtering, and enhancing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Primary Image Picker Card
                      _buildPrimaryPickerCard(),
                      const SizedBox(height: 24),

                      // Quick Action Buttons
                      _buildQuickActionButtons(),
                      const SizedBox(height: 48),

                      // Feature Highlights Preview
                      _buildFeatureHighlights(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading image into studio...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryPickerCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : () => _pickImage(ImageSource.gallery),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF334155),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF6366F1)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 38,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose a Photo to Edit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to browse device files or photo library',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildFormatChip('JPEG'),
                  _buildFormatChip('PNG'),
                  _buildFormatChip('WEBP'),
                  _buildFormatChip('BMP'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF334155).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF475569).withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.camera_alt_rounded,
            label: 'Camera',
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.auto_awesome_rounded,
            label: 'Sample',
            isAccent: true,
            onTap: _loadSampleImage,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isAccent
                ? const Color(0xFF06B6D4).withValues(alpha: 0.12)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAccent
                  ? const Color(0xFF06B6D4).withValues(alpha: 0.5)
                  : const Color(0xFF334155),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isAccent ? const Color(0xFF06B6D4) : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isAccent ? const Color(0xFF06B6D4) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flash_on_rounded,
              size: 16,
              color: Color(0xFF06B6D4),
            ),
            const SizedBox(width: 6),
            Text(
              'STUDIO CAPABILITIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 550;
            final items = [
              _buildFeatureCard(
                icon: Icons.tune_rounded,
                title: 'Image Adjustments',
                description:
                    'Brightness, contrast, saturation, sharpness & temperature.',
              ),
              _buildFeatureCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Artistic Filters',
                description:
                    'Presets, cinematic tints, black & white, and vintage looks.',
              ),
              _buildFeatureCard(
                icon: Icons.crop_rotate_rounded,
                title: 'Transform & Crop',
                description:
                    'Aspect ratios, 90° rotations, and horizontal/vertical flips.',
              ),
              _buildFeatureCard(
                icon: Icons.title_rounded,
                title: 'Text & Overlays',
                description:
                    'Custom fonts, stickers, colors, and dynamic watermark placement.',
              ),
            ];

            if (isWide) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.3,
                children: items,
              );
            } else {
              return Column(
                children: items
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: item,
                        ))
                    .toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1F2937),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
