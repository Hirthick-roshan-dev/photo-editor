import 'package:flutter/material.dart';
import '../models/editable_image.dart';
import '../utils/image_cropper.dart';
import '../widgets/crop_overlay.dart';

class CropScreen extends StatefulWidget {
  final EditableImage image;

  const CropScreen({super.key, required this.image});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final GlobalKey<CropOverlayState> _cropOverlayKey =
      GlobalKey<CropOverlayState>();

  bool _isProcessing = false;

  // Crop & Transform state
  Rect? _cropRect;
  Size? _lastDisplaySize;
  double? _selectedAspectRatio; // null = Free
  int _cropRotation = 0; // 0, 90, 180, 270
  bool _flipH = false;
  bool _flipV = false;
  String _selectedRatioLabel = 'Free';

  final List<_AspectRatioPreset> _aspectRatios = const [
    _AspectRatioPreset(
      label: 'Free',
      icon: Icons.crop_free_rounded,
      ratio: null,
    ),
    _AspectRatioPreset(
      label: 'Original',
      icon: Icons.image_outlined,
      ratio: -1.0,
    ),
    _AspectRatioPreset(
      label: '1:1',
      icon: Icons.crop_square_rounded,
      ratio: 1.0,
    ),
    _AspectRatioPreset(
      label: '4:3',
      icon: Icons.crop_landscape_rounded,
      ratio: 4.0 / 3.0,
    ),
    _AspectRatioPreset(
      label: '3:4',
      icon: Icons.crop_portrait_rounded,
      ratio: 3.0 / 4.0,
    ),
    _AspectRatioPreset(
      label: '16:9',
      icon: Icons.crop_16_9_rounded,
      ratio: 16.0 / 9.0,
    ),
    _AspectRatioPreset(
      label: '9:16',
      icon: Icons.crop_portrait_rounded,
      ratio: 9.0 / 16.0,
    ),
    _AspectRatioPreset(
      label: '3:2',
      icon: Icons.crop_landscape_rounded,
      ratio: 3.0 / 2.0,
    ),
    _AspectRatioPreset(
      label: '2:3',
      icon: Icons.crop_portrait_rounded,
      ratio: 2.0 / 3.0,
    ),
  ];

  void _onSelectAspectRatio(_AspectRatioPreset preset) {
    setState(() {
      _selectedRatioLabel = preset.label;
      if (preset.ratio == null) {
        _selectedAspectRatio = null;
      } else if (preset.ratio == -1.0) {
        // Original aspect ratio
        if (widget.image.width != null &&
            widget.image.height != null &&
            widget.image.height! > 0) {
          _selectedAspectRatio = widget.image.width! / widget.image.height!;
        } else {
          _selectedAspectRatio = 1.0;
        }
      } else {
        _selectedAspectRatio = preset.ratio;
      }
    });
    _cropOverlayKey.currentState?.setAspectRatio(_selectedAspectRatio);
  }

  void _rotateClockwise() {
    setState(() {
      _cropRotation = (_cropRotation + 90) % 360;
    });
  }

  void _flipHorizontal() {
    setState(() {
      _flipH = !_flipH;
    });
  }

  void _resetCropBox() {
    setState(() {
      _selectedAspectRatio = null;
      _selectedRatioLabel = 'Free';
      _cropRotation = 0;
      _flipH = false;
      _flipV = false;
    });
    _cropOverlayKey.currentState?.resetToFull();
  }

  Future<void> _applyAndReturn() async {
    if (_cropRect == null || _lastDisplaySize == null) {
      Navigator.of(context).pop();
      return;
    }

    final Size displaySize = _lastDisplaySize!;
    if (displaySize.width <= 0 || displaySize.height <= 0) return;

    final double normLeft = (_cropRect!.left / displaySize.width).clamp(
      0.0,
      1.0,
    );
    final double normTop = (_cropRect!.top / displaySize.height).clamp(
      0.0,
      1.0,
    );
    final double normWidth = (_cropRect!.width / displaySize.width).clamp(
      0.0,
      1.0 - normLeft,
    );
    final double normHeight = (_cropRect!.height / displaySize.height).clamp(
      0.0,
      1.0 - normTop,
    );

    final Rect normalizedRect = Rect.fromLTWH(
      normLeft,
      normTop,
      normWidth,
      normHeight,
    );

    setState(() => _isProcessing = true);

    try {
      final EditableImage cropped = await ImageCropper.cropImage(
        image: widget.image,
        normalizedCropRect: normalizedRect,
        rotationDegrees: _cropRotation,
        flipHorizontal: _flipH,
        flipVertical: _flipV,
      );

      if (!mounted) return;
      Navigator.of(context).pop(cropped);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Failed to crop image: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            size: 22,
            color: Color(0xFF0F172A),
          ),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Crop',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: _resetCropBox,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reset'),
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: 12.0,
              top: 8,
              bottom: 8,
              left: 4,
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isProcessing ? null : _applyAndReturn,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Interactive Crop Canvas Area
              Expanded(
                child: Stack(
                  children: [
                    // Checkerboard background
                    Positioned.fill(
                      child: CustomPaint(painter: _LightCheckerboardPainter()),
                    ),

                    Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const double padding = 20.0;
                          final double maxW =
                              constraints.maxWidth - (padding * 2);
                          final double maxH =
                              constraints.maxHeight - (padding * 2);

                          if (maxW <= 0 || maxH <= 0) {
                            return const SizedBox.shrink();
                          }

                          final double imgAspect =
                              widget.image.width != null &&
                                  widget.image.height != null &&
                                  widget.image.height! > 0
                              ? widget.image.width! / widget.image.height!
                              : 1.0;

                          double displayW;
                          double displayH;

                          if (maxW / maxH > imgAspect) {
                            displayH = maxH;
                            displayW = displayH * imgAspect;
                          } else {
                            displayW = maxW;
                            displayH = displayW / imgAspect;
                          }

                          final Size displaySize = Size(displayW, displayH);
                          _lastDisplaySize = displaySize;
                          _cropRect ??= Rect.fromLTWH(0, 0, displayW, displayH);

                          return SizedBox(
                            width: displayW,
                            height: displayH,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.12,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Image.memory(
                                      widget.image.bytes,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: CropOverlay(
                                    key: _cropOverlayKey,
                                    imageDisplaySize: displaySize,
                                    initialCropRect: _cropRect!,
                                    fixedAspectRatio: _selectedAspectRatio,
                                    onCropRectChanged: (rect) {
                                      _cropRect = rect;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Light Themed Bottom Controls Panel
              _buildBottomControlsPanel(),
            ],
          ),

          // Processing Loading Indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: Card(
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Applying crop...',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControlsPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Transform Action Buttons (Rotate, Flip)
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //     children: [
            //       _buildLightTransformButton(
            //         icon: Icons.rotate_right_rounded,
            //         label: 'Rotate 90°',
            //         onTap: _rotateClockwise,
            //       ),
            //       _buildLightTransformButton(
            //         icon: Icons.flip_rounded,
            //         label: 'Flip H',
            //         isActive: _flipH,
            //         onTap: _flipHorizontal,
            //       ),
            //       _buildLightTransformButton(
            //         icon: Icons.restart_alt_rounded,
            //         label: 'Reset Box',
            //         onTap: _resetCropBox,
            //       ),
            //     ],
            //   ),
            // ),
            // const Divider(color: Color(0xFFE2E8F0), height: 12),

            // Aspect Ratio Presets Horizontal Scroll
            SizedBox(
              height: 60,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _aspectRatios.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final preset = _aspectRatios[index];
                  final isSelected = _selectedRatioLabel == preset.label;

                  return InkWell(
                    onTap: () => _onSelectAspectRatio(preset),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            preset.icon,
                            size: 16,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            preset.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildLightTransformButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AspectRatioPreset {
  final String label;
  final IconData icon;
  final double? ratio;

  const _AspectRatioPreset({
    required this.label,
    required this.icon,
    required this.ratio,
  });
}

class _LightCheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double squareSize = 16.0;
    final paint1 = Paint()..color = const Color(0xFFF1F5F9);
    final paint2 = Paint()..color = const Color(0xFFE2E8F0);

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final bool isEven =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
