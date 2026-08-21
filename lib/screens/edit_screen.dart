import 'package:flutter/material.dart';
import '../models/editable_image.dart';

class EditScreen extends StatefulWidget {
  final EditableImage image;

  const EditScreen({super.key, required this.image});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final TransformationController _transformationController =
      TransformationController();
  int _selectedToolIndex = 0;

  final List<_ToolItem> _tools = const [
    _ToolItem(icon: Icons.tune_rounded, label: 'Adjust'),
    _ToolItem(icon: Icons.auto_awesome_rounded, label: 'Filters'),
    _ToolItem(icon: Icons.crop_rotate_rounded, label: 'Crop'),
    _ToolItem(icon: Icons.title_rounded, label: 'Text'),
    _ToolItem(icon: Icons.brush_rounded, label: 'Draw'),
    _ToolItem(icon: Icons.emoji_emotions_outlined, label: 'Stickers'),
  ];

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back to Home',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.image.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (widget.image.resolution.isNotEmpty) ...[
                  Text(
                    widget.image.resolution,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.cyanAccent.shade100,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    ' • ',
                    style: TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
                Text(
                  widget.image.formattedSize,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset Zoom & Edits',
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
            padding: const EdgeInsets.only(right: 12.0, top: 8, bottom: 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF06B6D4)),
                        const SizedBox(width: 10),
                        Text(
                          'Ready to export ${widget.image.name}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text(
                'Export',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Workspace Canvas with interactive zoom/pan
          Expanded(
            child: Stack(
              children: [
                // Background dark checkered workspace
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CheckerboardPainter(),
                  ),
                ),
                // Interactive viewer for image
                Center(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.2,
                    maxScale: 6.0,
                    boundaryMargin: const EdgeInsets.all(80.0),
                    child: Hero(
                      tag: 'image_${widget.image.name}',
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.memory(
                          widget.image.bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                // Zoom reset floating quick badge
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'reset_zoom_fab',
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    tooltip: 'Reset Pan & Zoom',
                    onPressed: _resetZoom,
                    child: const Icon(Icons.fit_screen_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Tool Controls & Options Panel
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              border: Border(
                top: BorderSide(color: Color(0xFF1F2937), width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active tool sub-panel description
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _tools[_selectedToolIndex].icon,
                              size: 18,
                              color: const Color(0xFF06B6D4),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tools[_selectedToolIndex].label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Tap tools below to switch mode',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFF1F2937)),

                  // Tool icons list
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
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
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF06B6D4).withValues(alpha: 0.15)
                                  : const Color(0xFF1F2937).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF06B6D4)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tool.icon,
                                  size: 22,
                                  color: isSelected
                                      ? const Color(0xFF06B6D4)
                                      : Colors.white70,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tool.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}

class _ToolItem {
  final IconData icon;
  final String label;

  const _ToolItem({required this.icon, required this.label});
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double squareSize = 16.0;
    final paint1 = Paint()..color = const Color(0xFF0D131F);
    final paint2 = Paint()..color = const Color(0xFF131B2A);

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
