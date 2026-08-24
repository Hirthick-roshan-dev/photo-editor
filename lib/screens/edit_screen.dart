import 'package:flutter/material.dart';
import '../models/editable_image.dart';
import 'crop_screen.dart';
import 'draw_screen.dart';
import 'filter_screen.dart';

class EditScreen extends StatefulWidget {
  final EditableImage image;

  const EditScreen({super.key, required this.image});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final TransformationController _transformationController =
      TransformationController();

  late EditableImage _currentImage;
  final List<EditableImage> _undoHistory = [];
  final List<EditableImage> _redoHistory = [];

  int _selectedToolIndex = 0;

  final List<_ToolItem> _tools = const [
    _ToolItem(icon: Icons.tune_rounded, label: 'Adjust'),
    _ToolItem(icon: Icons.auto_awesome_rounded, label: 'Filters'),
    _ToolItem(icon: Icons.crop_rotate_rounded, label: 'Crop'),
    _ToolItem(icon: Icons.title_rounded, label: 'Text'),
    _ToolItem(icon: Icons.brush_rounded, label: 'Draw'),
    _ToolItem(icon: Icons.emoji_emotions_outlined, label: 'Stickers'),
  ];

  @override
  void initState() {
    super.initState();
    _currentImage = widget.image;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Future<void> _openFilterScreen() async {
    final EditableImage? filtered = await Navigator.of(context)
        .push<EditableImage>(
          MaterialPageRoute(
            builder: (context) => FilterScreen(image: _currentImage),
          ),
        );

    if (filtered != null && mounted && filtered != _currentImage) {
      setState(() {
        _undoHistory.add(_currentImage);
        _redoHistory.clear();
        _currentImage = filtered;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Filter applied (${filtered.formattedSize})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openCropScreen() async {
    final EditableImage? cropped = await Navigator.of(context)
        .push<EditableImage>(
          MaterialPageRoute(
            builder: (context) => CropScreen(image: _currentImage),
          ),
        );

    if (cropped != null && mounted) {
      setState(() {
        _undoHistory.add(_currentImage);
        _redoHistory.clear();
        _currentImage = cropped;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cropped to ${cropped.resolution} (${cropped.formattedSize})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openDrawScreen() async {
    final EditableImage? drawn = await Navigator.of(context)
        .push<EditableImage>(
          MaterialPageRoute(
            builder: (context) => DrawScreen(image: _currentImage),
          ),
        );

    if (drawn != null && mounted && drawn != _currentImage) {
      setState(() {
        _undoHistory.add(_currentImage);
        _redoHistory.clear();
        _currentImage = drawn;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.brush_rounded,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Drawing saved (${drawn.resolution})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _undo() {
    if (_undoHistory.isNotEmpty) {
      setState(() {
        _redoHistory.add(_currentImage);
        _currentImage = _undoHistory.removeLast();
      });
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      setState(() {
        _undoHistory.add(_currentImage);
        _currentImage = _redoHistory.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF0F172A),
          ),
          tooltip: 'Back to Home',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text(
            //   _currentImage.name,
            //   maxLines: 1,
            //   overflow: TextOverflow.ellipsis,
            //   style: const TextStyle(
            //     fontSize: 14,
            //     fontWeight: FontWeight.w600,
            //     color: Color(0xFF0F172A),
            //   ),
            // ),
            // const SizedBox(height: 1),
            // Text.rich(
            //   TextSpan(
            //     children: [
            //       if (_currentImage.resolution.isNotEmpty) ...[
            //         TextSpan(
            //           text: _currentImage.resolution,
            //           style: const TextStyle(
            //             fontSize: 10.5,
            //             color: Color(0xFF2563EB),
            //             fontWeight: FontWeight.w600,
            //           ),
            //         ),
            //         const TextSpan(
            //           text: ' • ',
            //           style: TextStyle(
            //             fontSize: 10.5,
            //             color: Color(0xFF94A3B8),
            //           ),
            //         ),
            //       ],
            //       TextSpan(
            //         text: _currentImage.formattedSize,
            //         style: const TextStyle(
            //           fontSize: 10.5,
            //           color: Color(0xFF64748B),
            //         ),
            //       ),
            //     ],
            //   ),
            //   maxLines: 1,
            //   overflow: TextOverflow.ellipsis,
            // ),
          ],
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              Icons.undo_rounded,
              size: 20,
              color: _undoHistory.isNotEmpty
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFCBD5E1),
            ),
            tooltip: 'Undo',
            onPressed: _undoHistory.isNotEmpty ? _undo : null,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              Icons.redo_rounded,
              size: 20,
              color: _redoHistory.isNotEmpty
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFCBD5E1),
            ),
            tooltip: 'Redo',
            onPressed: _redoHistory.isNotEmpty ? _redo : null,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(
              Icons.restart_alt_rounded,
              size: 20,
              color: Color(0xFF475569),
            ),
            tooltip: 'Reset Zoom',
            onPressed: () {
              _resetZoom();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Canvas view reset'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 4.0,
              right: 8.0,
              top: 8,
              bottom: 8,
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF38BDF8),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ready to export ${_currentImage.name}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text(
                'Export',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas Workspace with interactive zoom/pan
          Expanded(
            child: Stack(
              children: [
                // Background subtle checkerboard pattern
                Positioned.fill(
                  child: CustomPaint(painter: _LightCheckerboardPainter()),
                ),

                // Interactive viewer for image
                Center(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.2,
                    maxScale: 6.0,
                    boundaryMargin: const EdgeInsets.all(80.0),
                    child: Hero(
                      tag: 'image_${_currentImage.name}',
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.memory(
                          _currentImage.bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // Zoom reset floating quick button
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'reset_zoom_fab',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 3,
                    tooltip: 'Reset Pan & Zoom',
                    onPressed: _resetZoom,
                    child: const Icon(Icons.fit_screen_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Tools List
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 84,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _tools.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tool = _tools[index];
                    final isSelected = _selectedToolIndex == index;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedToolIndex = index;
                        });
                        if (index == 1) {
                          // Filters Tool Tapped -> Open dedicated FilterScreen
                          _openFilterScreen();
                        } else if (index == 2) {
                          // Crop Tool Tapped -> Open dedicated CropScreen
                          _openCropScreen();
                        } else if (index == 4) {
                          // Draw Tool Tapped -> Open dedicated DrawScreen
                          _openDrawScreen();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tool.icon,
                              size: 22,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tool.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String label;

  const _ToolItem({required this.icon, required this.label});
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
