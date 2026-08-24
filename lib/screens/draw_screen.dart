import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';
import '../models/editable_image.dart';
import '../utils/image_draw_applier.dart';

class DrawScreen extends StatefulWidget {
  final EditableImage image;

  const DrawScreen({super.key, required this.image});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final TransformationController _transformationController =
      TransformationController();

  // Drawing state & history
  final List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _redoStrokes = [];
  DrawingStroke? _currentStroke;

  // Selected tool settings
  DrawToolType _selectedTool = DrawToolType.pen;
  Color _selectedColor = const Color(0xFFEF4444); // Default vibrant red
  double _strokeWidth = 6.0;
  double _opacity = 1.0;
  bool _isFilled = false; // For shapes (rectangle, circle)

  // Modes
  bool _isPanZoomMode = false;
  bool _isProcessing = false;

  // Bottom panel tab (0: Tools, 1: Size & Opacity, 2: Colors)
  int _activeBottomTab = 0;

  // Curated color palette
  static const List<Color> _presetColors = [
    Color(0xFFFFFFFF), // White
    Color(0xFF0F172A), // Dark Slate / Black
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFFACC15), // Yellow
    Color(0xFF10B981), // Emerald
    Color(0xFF00FF66), // Neon Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFF2563EB), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFD97706), // Amber
    Color(0xFF64748B), // Slate Grey
    Color(0xFF831843), // Maroon
  ];

  static const List<double> _presetStrokeWidths = [2.0, 6.0, 12.0, 20.0, 32.0];

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        final removed = _strokes.removeLast();
        _redoStrokes.add(removed);
      });
    }
  }

  void _redo() {
    if (_redoStrokes.isNotEmpty) {
      setState(() {
        final restored = _redoStrokes.removeLast();
        _strokes.add(restored);
      });
    }
  }

  void _clearAll() {
    if (_strokes.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all drawings?'),
        content: const Text(
          'This will remove all strokes from this drawing session. This action can be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _redoStrokes.addAll(_strokes.reversed);
                _strokes.clear();
              });
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // --- Gesture Handling with 100% Stroke Point Accuracy ---

  void _onPanStart(Offset localPosition, Size displaySize) {
    if (_isPanZoomMode) return;

    final Offset clamped = Offset(
      localPosition.dx.clamp(0.0, displaySize.width),
      localPosition.dy.clamp(0.0, displaySize.height),
    );

    setState(() {
      _currentStroke = DrawingStroke(
        points: [clamped],
        color: _selectedColor,
        strokeWidth: _strokeWidth,
        opacity: _opacity,
        toolType: _selectedTool,
        canvasSize: displaySize,
        isFilled: _isFilled,
      );
    });
  }

  void _onPanUpdate(Offset localPosition, Size displaySize) {
    if (_isPanZoomMode || _currentStroke == null) return;

    final Offset clamped = Offset(
      localPosition.dx.clamp(0.0, displaySize.width),
      localPosition.dy.clamp(0.0, displaySize.height),
    );

    setState(() {
      final List<Offset> updatedPoints = List.from(_currentStroke!.points);

      // For shapes (line, arrow, rect, circle), update the end point
      if (_selectedTool == DrawToolType.line ||
          _selectedTool == DrawToolType.arrow ||
          _selectedTool == DrawToolType.rectangle ||
          _selectedTool == DrawToolType.circle) {
        if (updatedPoints.length < 2) {
          updatedPoints.add(clamped);
        } else {
          updatedPoints[1] = clamped;
        }
      } else {
        // Freehand tools: add continuous path point if moved enough
        if (updatedPoints.isEmpty ||
            (clamped - updatedPoints.last).distanceSquared >= 1.0) {
          updatedPoints.add(clamped);
        }
      }

      _currentStroke = _currentStroke!.copyWith(points: updatedPoints);
    });
  }

  void _onPanEnd(Size displaySize) {
    if (_isPanZoomMode || _currentStroke == null) return;

    setState(() {
      if (_currentStroke!.points.isNotEmpty) {
        _strokes.add(_currentStroke!);
        _redoStrokes.clear();
      }
      _currentStroke = null;
    });
  }

  void _onPanCancel() {
    if (_currentStroke != null) {
      setState(() {
        _currentStroke = null;
      });
    }
  }

  Future<void> _applyAndReturn() async {
    if (_strokes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final EditableImage drawn = await ImageDrawApplier.applyDrawings(
        image: widget.image,
        strokes: _strokes,
      );

      if (!mounted) return;
      Navigator.of(context).pop(drawn);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Failed to apply drawing: $e'),
        ),
      );
    }
  }

  void _openCustomColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomColorPickerSheet(
        initialColor: _selectedColor,
        onColorSelected: (newColor) {
          setState(() {
            _selectedColor = newColor;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            Icons.close_rounded,
            size: 22,
            color: Color(0xFF0F172A),
          ),
          tooltip: 'Cancel',
          onPressed: () {
            if (_strokes.isNotEmpty) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Discard drawing?'),
                  content: const Text(
                    'Are you sure you want to discard your drawing changes?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Keep Editing'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Row(
          children: [
            const Text(
              'Draw',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isPanZoomMode
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPanZoomMode
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPanZoomMode
                        ? Icons.pan_tool_rounded
                        : _selectedTool.icon,
                    size: 13,
                    color: _isPanZoomMode
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPanZoomMode ? 'Pan & Zoom' : _selectedTool.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isPanZoomMode
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Undo
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.undo_rounded,
              size: 20,
              color: _strokes.isNotEmpty
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFCBD5E1),
            ),
            tooltip: 'Undo stroke',
            onPressed: _strokes.isNotEmpty ? _undo : null,
          ),
          // Redo
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.redo_rounded,
              size: 20,
              color: _redoStrokes.isNotEmpty
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFCBD5E1),
            ),
            tooltip: 'Redo stroke',
            onPressed: _redoStrokes.isNotEmpty ? _redo : null,
          ),
          // Clear all
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: _strokes.isNotEmpty
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFCBD5E1),
            ),
            tooltip: 'Clear all',
            onPressed: _strokes.isNotEmpty ? _clearAll : null,
          ),
          // Pan/Zoom Mode Toggle
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _isPanZoomMode ? Icons.edit_rounded : Icons.pan_tool_rounded,
              size: 20,
              color: _isPanZoomMode
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF475569),
            ),
            tooltip: _isPanZoomMode ? 'Switch to Drawing' : 'Pan & Zoom Canvas',
            onPressed: () {
              setState(() {
                _isPanZoomMode = !_isPanZoomMode;
              });
            },
          ),
          // Apply Button
          Padding(
            padding: const EdgeInsets.only(
              right: 12.0,
              left: 4.0,
              top: 8,
              bottom: 8,
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
      body: Column(
        children: [
          // Canvas Viewport Area
          Expanded(
            child: Stack(
              children: [
                // Background subtle checkerboard pattern
                Positioned.fill(
                  child: CustomPaint(painter: _LightCheckerboardPainter()),
                ),

                // Centered Interactive Image Canvas
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const double padding = 24.0;
                      final double maxW = math.max(
                        10.0,
                        constraints.maxWidth - padding,
                      );
                      final double maxH = math.max(
                        10.0,
                        constraints.maxHeight - padding,
                      );

                      final double imgAspect =
                          (widget.image.width != null &&
                              widget.image.height != null &&
                              widget.image.height! > 0)
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

                      return InteractiveViewer(
                        transformationController: _transformationController,
                        panEnabled: _isPanZoomMode,
                        scaleEnabled: _isPanZoomMode,
                        minScale: 0.5,
                        maxScale: 6.0,
                        boundaryMargin: const EdgeInsets.all(80.0),
                        child: Container(
                          width: displayW,
                          height: displayH,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Base Image
                              Image.memory(
                                widget.image.bytes,
                                width: displayW,
                                height: displayH,
                                fit: BoxFit.fill,
                              ),

                              // Realtime Drawing Canvas and Accurate Gesture Handler
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanDown: (details) => _onPanStart(
                                  details.localPosition,
                                  displaySize,
                                ),
                                onPanUpdate: (details) => _onPanUpdate(
                                  details.localPosition,
                                  displaySize,
                                ),
                                onPanEnd: (_) => _onPanEnd(displaySize),
                                onPanCancel: _onPanCancel,
                                child: CustomPaint(
                                  size: displaySize,
                                  painter: _DrawingPainter(
                                    strokes: _strokes,
                                    currentStroke: _currentStroke,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Reset zoom floating button when zoomed
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'reset_draw_zoom',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 3,
                    tooltip: 'Reset Pan & Zoom',
                    onPressed: _resetZoom,
                    child: const Icon(Icons.fit_screen_rounded, size: 18),
                  ),
                ),

                // Processing indicator overlay
                if (_isProcessing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: const Center(
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                SizedBox(width: 14),
                                Text(
                                  'Applying drawings...',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Control Panel
          _buildBottomControlPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomControlPanel() {
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
            // Top Navigation Tabs (Tools, Size & Opacity, Colors)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: Row(
                children: [
                  _buildTabButton(
                    index: 0,
                    icon: Icons.brush_rounded,
                    label: 'Tools',
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    index: 1,
                    icon: Icons.tune_rounded,
                    label: 'Size & Opacity',
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    index: 2,
                    icon: Icons.palette_rounded,
                    label: 'Color',
                    trailing: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: _buildActiveTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    Widget? trailing,
  }) {
    final bool isSelected = _activeBottomTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeBottomTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeBottomTab) {
      case 0:
        return _buildToolsTab();
      case 1:
        return _buildSizeAndOpacityTab();
      case 2:
        return _buildColorsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildToolsTab() {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...DrawToolType.values.map((tool) {
            final isSelected = _selectedTool == tool;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTool = tool;
                    _isPanZoomMode = false;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tool.icon,
                        size: 20,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tool.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
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
              ),
            );
          }),

          // Fill toggle for shapes
          if (_selectedTool == DrawToolType.rectangle ||
              _selectedTool == DrawToolType.circle)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: ActionChip(
                avatar: Icon(
                  _isFilled
                      ? Icons.format_color_fill_rounded
                      : Icons.border_clear_rounded,
                  size: 16,
                  color: _isFilled ? Colors.white : const Color(0xFF2563EB),
                ),
                backgroundColor: _isFilled
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFEFF6FF),
                label: Text(
                  _isFilled ? 'Filled' : 'Outline',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isFilled ? Colors.white : const Color(0xFF2563EB),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isFilled = !_isFilled;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSizeAndOpacityTab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stroke Size row
        Row(
          children: [
            const SizedBox(
              width: 60,
              child: Text(
                'Size',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                ),
                child: Slider(
                  value: _strokeWidth,
                  min: 1.0,
                  max: 48.0,
                  activeColor: const Color(0xFF2563EB),
                  inactiveColor: const Color(0xFFE2E8F0),
                  onChanged: (val) => setState(() => _strokeWidth = val),
                ),
              ),
            ),
            // Live thickness indicator preview
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Container(
                width: math.min(26.0, _strokeWidth),
                height: math.min(26.0, _strokeWidth),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: _opacity),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),

        // Opacity row
        Row(
          children: [
            const SizedBox(
              width: 60,
              child: Text(
                'Opacity',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                ),
                child: Slider(
                  value: _opacity,
                  min: 0.1,
                  max: 1.0,
                  activeColor: const Color(0xFF2563EB),
                  inactiveColor: const Color(0xFFE2E8F0),
                  onChanged: (val) => setState(() => _opacity = val),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${(_opacity * 100).round()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),

        // Quick Preset size buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _presetStrokeWidths.map((preset) {
            final bool isSelected = (_strokeWidth - preset).abs() < 1.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: InkWell(
                onTap: () => setState(() => _strokeWidth = preset),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: preset.clamp(2.0, 14.0),
                        height: preset.clamp(2.0, 14.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${preset.round()}px',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorsTab() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Custom color picker button
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: InkWell(
              onTap: _openCustomColorPicker,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Colors.red,
                      Colors.yellow,
                      Colors.green,
                      Colors.cyan,
                      Colors.blue,
                      Colors.purple,
                      Colors.red,
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                ),
                child: const Icon(
                  Icons.colorize_rounded,
                  size: 18,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Preset color chips
          ..._presetColors.map((color) {
            final bool isSelected = _selectedColor == color;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () => setState(() => _selectedColor = color),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// --- Realtime Drawing Painter ---

class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;

  _DrawingPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty && currentStroke == null) return;

    // Use saveLayer so BlendMode.clear (eraser) only affects drawn strokes
    final Rect bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(bounds, Paint());

    for (final stroke in strokes) {
      stroke.renderToCanvas(canvas, size);
    }

    if (currentStroke != null) {
      currentStroke!.renderToCanvas(canvas, size);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

// --- Checkerboard Background Painter ---

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

// --- Custom HSV Color Picker Bottom Sheet ---

class _CustomColorPickerSheet extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const _CustomColorPickerSheet({
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_CustomColorPickerSheet> createState() =>
      _CustomColorPickerSheetState();
}

class _CustomColorPickerSheetState extends State<_CustomColorPickerSheet> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final Color currentColor = _hsvColor.toColor();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              const Text(
                'Custom Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  widget.onColorSelected(currentColor);
                  Navigator.of(context).pop();
                },
                child: const Text('Select'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hue Slider
          const Text(
            'Hue',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: _hsvColor.hue,
              min: 0.0,
              max: 360.0,
              activeColor: const Color(0xFF2563EB),
              onChanged: (val) {
                setState(() => _hsvColor = _hsvColor.withHue(val));
              },
            ),
          ),

          // Saturation Slider
          const Text(
            'Saturation',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: _hsvColor.saturation,
              min: 0.0,
              max: 1.0,
              activeColor: const Color(0xFF2563EB),
              onChanged: (val) {
                setState(() => _hsvColor = _hsvColor.withSaturation(val));
              },
            ),
          ),

          // Value (Brightness) Slider
          const Text(
            'Brightness',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: _hsvColor.value,
              min: 0.0,
              max: 1.0,
              activeColor: const Color(0xFF2563EB),
              onChanged: (val) {
                setState(() => _hsvColor = _hsvColor.withValue(val));
              },
            ),
          ),
        ],
      ),
    );
  }
}
