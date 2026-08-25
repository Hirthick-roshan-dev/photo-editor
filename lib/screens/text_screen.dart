import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/editable_image.dart';
import '../models/text_layer.dart';
import '../utils/image_text_applier.dart';

class TextScreen extends StatefulWidget {
  final EditableImage image;

  const TextScreen({super.key, required this.image});

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  final TransformationController _transformationController =
      TransformationController();

  // Active layers and selection
  List<TextLayer> _layers = [];
  String? _selectedLayerId;

  // History for Undo / Redo
  final List<List<TextLayer>> _undoHistory = [];
  final List<List<TextLayer>> _redoHistory = [];

  // Modes & UI state
  bool _isPanZoomMode = false;
  bool _isProcessing = false;
  int _activeBottomTab = 0; // 0: Text/Font, 1: Color, 2: Badge, 3: Effects, 4: Layers

  Size _currentDisplaySize = const Size(400, 400);

  // Gesture scaling & rotating tracker for selected layer
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _initialTouchPos = Offset.zero;
  Offset _initialLayerPos = Offset.zero;

  // Curated color palette
  static const List<Color> _presetColors = [
    Color(0xFFFFFFFF), // White
    Color(0xFF0F172A), // Slate Black
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFFACC15), // Yellow
    Color(0xFF10B981), // Emerald
    Color(0xFF00FF66), // Neon Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFF2563EB), // Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFD97706), // Amber
    Color(0xFF64748B), // Slate Grey
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with a default text layer centered on canvas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _layers.isEmpty) {
        _addNewTextLayer(text: 'Add Text Here');
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  TextLayer? get _selectedLayer {
    if (_selectedLayerId == null) return null;
    try {
      return _layers.firstWhere((l) => l.id == _selectedLayerId);
    } catch (_) {
      return null;
    }
  }

  void _recordHistory() {
    _undoHistory.add(_layers.map((l) => l.copyWith()).toList());
    _redoHistory.clear();
  }

  void _undo() {
    if (_undoHistory.isNotEmpty) {
      setState(() {
        _redoHistory.add(_layers.map((l) => l.copyWith()).toList());
        _layers = _undoHistory.removeLast();
        if (_selectedLayerId != null &&
            !_layers.any((l) => l.id == _selectedLayerId)) {
          _selectedLayerId = _layers.isNotEmpty ? _layers.last.id : null;
        }
      });
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      setState(() {
        _undoHistory.add(_layers.map((l) => l.copyWith()).toList());
        _layers = _redoHistory.removeLast();
        if (_selectedLayerId != null &&
            !_layers.any((l) => l.id == _selectedLayerId)) {
          _selectedLayerId = _layers.isNotEmpty ? _layers.last.id : null;
        }
      });
    }
  }

  void _addNewTextLayer({String text = 'Text Layer'}) {
    _recordHistory();
    final String newId =
        'layer_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
    final Offset center = Offset(
      _currentDisplaySize.width / 2,
      _currentDisplaySize.height / 2,
    );

    final newLayer = TextLayer(
      id: newId,
      text: text,
      position: center,
      fontSize: 30.0,
      scale: 1.0,
      rotation: 0.0,
      color: const Color(0xFFFFFFFF),
      opacity: 1.0,
      fontWeight: FontWeight.w700,
      textAlign: TextAlign.center,
      hasShadow: true,
      shadowColor: const Color(0x99000000),
      shadowBlurRadius: 4.0,
      canvasSize: _currentDisplaySize,
    );

    setState(() {
      _layers.add(newLayer);
      _selectedLayerId = newId;
    });
  }

  void _updateSelectedLayer(
    TextLayer Function(TextLayer) updater, {
    bool record = true,
  }) {
    if (_selectedLayerId == null) return;
    if (record) _recordHistory();

    setState(() {
      final index = _layers.indexWhere((l) => l.id == _selectedLayerId);
      if (index != -1) {
        _layers[index] = updater(_layers[index]);
      }
    });
  }

  void _deleteLayer(String id) {
    _recordHistory();
    setState(() {
      _layers.removeWhere((l) => l.id == id);
      if (_selectedLayerId == id) {
        _selectedLayerId = _layers.isNotEmpty ? _layers.last.id : null;
      }
    });
  }

  void _duplicateLayer(String id) {
    final index = _layers.indexWhere((l) => l.id == id);
    if (index == -1) return;

    _recordHistory();
    final original = _layers[index];
    final String newId =
        'layer_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
    final duplicated = original.copyWith(
      id: newId,
      position: Offset(
        (original.position.dx + 20).clamp(20.0, _currentDisplaySize.width - 20),
        (original.position.dy + 20).clamp(20.0, _currentDisplaySize.height - 20),
      ),
    );

    setState(() {
      _layers.add(duplicated);
      _selectedLayerId = newId;
    });
  }

  void _bringForward(String id) {
    final index = _layers.indexWhere((l) => l.id == id);
    if (index != -1 && index < _layers.length - 1) {
      _recordHistory();
      setState(() {
        final item = _layers.removeAt(index);
        _layers.insert(index + 1, item);
      });
    }
  }

  void _sendBackward(String id) {
    final index = _layers.indexWhere((l) => l.id == id);
    if (index > 0) {
      _recordHistory();
      setState(() {
        final item = _layers.removeAt(index);
        _layers.insert(index - 1, item);
      });
    }
  }

  Future<void> _openTextEditorDialog(TextLayer layer) async {
    final TextEditingController textController =
        TextEditingController(text: layer.text);

    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _TextEditBottomSheet(
          initialText: layer.text,
          controller: textController,
        );
      },
    );

    if (result != null && result.trim().isNotEmpty && mounted) {
      _updateSelectedLayer((l) => l.copyWith(text: result.trim()));
    }
  }

  Future<void> _applyAndReturn() async {
    if (_layers.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Ensure all layers have the updated canvas size before baking
      final List<TextLayer> normalizedLayers = _layers.map((layer) {
        return layer.copyWith(canvasSize: _currentDisplaySize);
      }).toList();

      final EditableImage renderedImage = await ImageTextApplier.applyTextLayers(
        image: widget.image,
        layers: normalizedLayers,
      );

      if (!mounted) return;
      Navigator.of(context).pop(renderedImage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Failed to apply text: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLayer = _selectedLayer;

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
            if (_layers.isNotEmpty) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Discard text changes?'),
                  content: const Text(
                    'Are you sure you want to discard your text layers?',
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
              'Add Text',
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
                        : Icons.title_rounded,
                    size: 13,
                    color: _isPanZoomMode
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPanZoomMode
                        ? 'Pan & Zoom'
                        : '${_layers.length} ${_layers.length == 1 ? "layer" : "layers"}',
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
              color: _undoHistory.isNotEmpty
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFCBD5E1),
            ),
            tooltip: 'Undo',
            onPressed: _undoHistory.isNotEmpty ? _undo : null,
          ),
          // Redo
          IconButton(
            visualDensity: VisualDensity.compact,
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
            tooltip: _isPanZoomMode ? 'Switch to Text Editing' : 'Pan & Zoom Canvas',
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
              icon: _isProcessing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                _isProcessing ? 'Saving...' : 'Apply',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas Area
          Expanded(
            child: Stack(
              children: [
                // Background Checkerboard Pattern
                Positioned.fill(
                  child: CustomPaint(painter: _LightCheckerboardPainter()),
                ),

                // Centered Interactive Canvas
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

                      _currentDisplaySize = Size(displayW, displayH);

                      return InteractiveViewer(
                        transformationController: _transformationController,
                        panEnabled: _isPanZoomMode,
                        scaleEnabled: _isPanZoomMode,
                        minScale: 0.5,
                        maxScale: 6.0,
                        boundaryMargin: const EdgeInsets.all(80.0),
                        child: GestureDetector(
                          onTap: () {
                            // Tap outside any text layer deselects
                            if (_selectedLayerId != null) {
                              setState(() {
                                _selectedLayerId = null;
                              });
                            }
                          },
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
                              clipBehavior: Clip.none,
                              children: [
                                // Base Image
                                Positioned.fill(
                                  child: Image.memory(
                                    widget.image.bytes,
                                    width: displayW,
                                    height: displayH,
                                    fit: BoxFit.fill,
                                  ),
                                ),

                                // Interactive Text Layers
                                for (final layer in _layers)
                                  _buildInteractiveTextLayer(
                                    layer,
                                    _currentDisplaySize,
                                    isSelected: layer.id == _selectedLayerId,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Floating Actions on Canvas (Add text + Pan & Zoom quick toggle)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'text_reset_zoom_fab',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 3,
                        tooltip: 'Reset Pan & Zoom',
                        onPressed: _resetZoom,
                        child: const Icon(Icons.fit_screen_rounded, size: 18),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.extended(
                        heroTag: 'add_text_fab',
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        onPressed: () => _addNewTextLayer(),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Add Text',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Control Panel
          _buildBottomControlPanel(selectedLayer),
        ],
      ),
    );
  }

  // --- Interactive Layer Placement & Handles ---

  Widget _buildInteractiveTextLayer(
    TextLayer layer,
    Size canvasSize, {
    required bool isSelected,
  }) {
    final Size measured = layer.measureSize();
    final double pad = layer.backgroundPadding;
    final double boxW = measured.width + pad * 2;
    final double boxH = measured.height + pad * 1.4;

    return Positioned(
      left: layer.position.dx - boxW / 2,
      top: layer.position.dy - boxH / 2,
      child: Transform.rotate(
        angle: layer.rotation,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              _selectedLayerId = layer.id;
            });
          },
          onDoubleTap: () => _openTextEditorDialog(layer),
          onScaleStart: (details) {
            if (_isPanZoomMode) return;
            setState(() {
              _selectedLayerId = layer.id;
            });
            _recordHistory();
            _baseScale = layer.scale;
            _baseRotation = layer.rotation;
            _initialTouchPos = details.focalPoint;
            _initialLayerPos = layer.position;
          },
          onScaleUpdate: (details) {
            if (_isPanZoomMode || _selectedLayerId != layer.id) return;

            final Offset delta = details.focalPoint - _initialTouchPos;
            final double newScale = (_baseScale * details.scale).clamp(0.2, 5.0);
            final double newRotation = _baseRotation + details.rotation;

            final Offset newPos = Offset(
              (_initialLayerPos.dx + delta.dx).clamp(0.0, canvasSize.width),
              (_initialLayerPos.dy + delta.dy).clamp(0.0, canvasSize.height),
            );

            setState(() {
              final idx = _layers.indexWhere((l) => l.id == layer.id);
              if (idx != -1) {
                _layers[idx] = _layers[idx].copyWith(
                  position: newPos,
                  scale: newScale,
                  rotation: newRotation,
                );
              }
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Visual Text Box (Custom painted)
              CustomPaint(
                size: Size(boxW, boxH),
                painter: _SingleTextLayerPainter(layer: layer),
              ),

              // Active Selection Frame & Corner Handles
              if (isSelected && !_isPanZoomMode) ...[
                // Selection Border
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF2563EB),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(
                          layer.backgroundStyle == TextBackgroundStyle.roundedPill
                              ? boxH / 2
                              : 8.0,
                        ),
                      ),
                    ),
                  ),
                ),

                // Top-Left: Edit text handle
                Positioned(
                  top: -14,
                  left: -14,
                  child: _buildHandleButton(
                    icon: Icons.edit_rounded,
                    color: const Color(0xFF2563EB),
                    tooltip: 'Edit text',
                    onTap: () => _openTextEditorDialog(layer),
                  ),
                ),

                // Top-Right: Delete handle
                Positioned(
                  top: -14,
                  right: -14,
                  child: _buildHandleButton(
                    icon: Icons.close_rounded,
                    color: const Color(0xFFEF4444),
                    tooltip: 'Delete layer',
                    onTap: () => _deleteLayer(layer.id),
                  ),
                ),

                // Bottom-Left: Duplicate handle
                Positioned(
                  bottom: -14,
                  left: -14,
                  child: _buildHandleButton(
                    icon: Icons.copy_rounded,
                    color: const Color(0xFF0F172A),
                    tooltip: 'Duplicate',
                    onTap: () => _duplicateLayer(layer.id),
                  ),
                ),

                // Bottom-Right: Scale & Rotate handle
                Positioned(
                  bottom: -14,
                  right: -14,
                  child: GestureDetector(
                    onPanStart: (d) {
                      _recordHistory();
                      _baseScale = layer.scale;
                      _baseRotation = layer.rotation;
                    },
                    onPanUpdate: (d) {
                      final double delta = (d.delta.dx + d.delta.dy) / 100.0;
                      final double newScale =
                          (layer.scale + delta).clamp(0.3, 4.0);
                      final double newRot = layer.rotation + (d.delta.dx * 0.02);

                      setState(() {
                        final idx = _layers.indexWhere((l) => l.id == layer.id);
                        if (idx != -1) {
                          _layers[idx] = _layers[idx].copyWith(
                            scale: newScale,
                            rotation: newRot,
                          );
                        }
                      });
                    },
                    child: _buildHandleButton(
                      icon: Icons.open_in_full_rounded,
                      color: const Color(0xFF2563EB),
                      tooltip: 'Resize & Rotate',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandleButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Icon(icon, size: 12, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // --- Bottom Control Panel with 5 Tabs ---

  Widget _buildBottomControlPanel(TextLayer? selected) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab Content Body
            Container(
              height: 140,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: selected == null
                  ? _buildNoSelectionTab()
                  : _buildSelectedTabContent(selected),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // Tab Bar Navigation
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  _buildTabButton(
                    index: 0,
                    icon: Icons.title_rounded,
                    label: 'Text & Font',
                  ),
                  _buildTabButton(
                    index: 1,
                    icon: Icons.palette_outlined,
                    label: 'Color',
                  ),
                  _buildTabButton(
                    index: 2,
                    icon: Icons.layers_outlined,
                    label: 'Badge',
                  ),
                  _buildTabButton(
                    index: 3,
                    icon: Icons.auto_fix_high_rounded,
                    label: 'Effects',
                  ),
                  _buildTabButton(
                    index: 4,
                    icon: Icons.format_list_bulleted_rounded,
                    label: 'Layers',
                  ),
                ],
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
  }) {
    final bool isSelected = _activeBottomTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeBottomTab = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSelectionTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.touch_app_rounded,
            size: 28,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a text layer on canvas or add a new one',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _addNewTextLayer(),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Text Layer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent(TextLayer selected) {
    switch (_activeBottomTab) {
      case 0:
        return _buildFontAndStyleTab(selected);
      case 1:
        return _buildColorAndOpacityTab(selected);
      case 2:
        return _buildBadgeAndBackgroundTab(selected);
      case 3:
        return _buildEffectsTab(selected);
      case 4:
        return _buildLayersTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Tab 0: Text & Font ---

  Widget _buildFontAndStyleTab(TextLayer selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Text Edit button + Alignment & Format toggles
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _openTextEditorDialog(selected),
                icon: const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF2563EB)),
                label: Text(
                  selected.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Alignments
            _buildToggleChip(
              icon: Icons.format_align_left_rounded,
              isActive: selected.textAlign == TextAlign.left,
              onTap: () => _updateSelectedLayer(
                (l) => l.copyWith(textAlign: TextAlign.left),
              ),
            ),
            const SizedBox(width: 4),
            _buildToggleChip(
              icon: Icons.format_align_center_rounded,
              isActive: selected.textAlign == TextAlign.center,
              onTap: () => _updateSelectedLayer(
                (l) => l.copyWith(textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 4),
            _buildToggleChip(
              icon: Icons.format_align_right_rounded,
              isActive: selected.textAlign == TextAlign.right,
              onTap: () => _updateSelectedLayer(
                (l) => l.copyWith(textAlign: TextAlign.right),
              ),
            ),
            const SizedBox(width: 6),

            // Uppercase Toggle
            _buildToggleChip(
              text: 'AA',
              isActive: selected.isUppercase,
              onTap: () => _updateSelectedLayer(
                (l) => l.copyWith(isUppercase: !l.isUppercase),
              ),
            ),
            const SizedBox(width: 4),

            // Bold Toggle
            _buildToggleChip(
              icon: Icons.format_bold_rounded,
              isActive: selected.fontWeight == FontWeight.w900 ||
                  selected.fontWeight == FontWeight.w800 ||
                  selected.fontWeight == FontWeight.w700,
              onTap: () => _updateSelectedLayer(
                (l) => l.copyWith(
                  fontWeight: l.fontWeight == FontWeight.w700
                      ? FontWeight.normal
                      : FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Italic Toggle
            _buildToggleChip(
              icon: Icons.format_italic_rounded,
              isActive: selected.fontStyle == FontStyle.italic,
              onTap: () => _updateSelectedLayer(
                (l) => l.copyWith(
                  fontStyle: l.fontStyle == FontStyle.italic
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Typography Font Presets Carousel
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: TextFontPreset.presets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = TextFontPreset.presets[index];
              final bool isCurrent =
                  selected.fontFamily == preset.fontFamily &&
                  selected.letterSpacing == preset.letterSpacing;

              return InkWell(
                onTap: () {
                  _updateSelectedLayer(
                    (l) => l.copyWith(
                      fontFamily: preset.fontFamily,
                      fontWeight: preset.fontWeight,
                      fontStyle: preset.fontStyle,
                      letterSpacing: preset.letterSpacing,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 92,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ag',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: preset.fontFamily,
                          fontWeight: preset.fontWeight,
                          fontStyle: preset.fontStyle,
                          color: isCurrent
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrent
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
      ],
    );
  }

  // --- Tab 1: Color & Opacity ---

  Widget _buildColorAndOpacityTab(TextLayer selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color Swatches Row
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _presetColors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final color = _presetColors[index];
              final bool isSelected = selected.color.value == color.value;

              return GestureDetector(
                onTap: () => _updateSelectedLayer((l) => l.copyWith(color: color)),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      width: isSelected ? 3.0 : 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Opacity Slider Row
        Row(
          children: [
            const Text(
              'Opacity',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            Expanded(
              child: Slider(
                value: selected.opacity,
                min: 0.1,
                max: 1.0,
                activeColor: const Color(0xFF2563EB),
                inactiveColor: const Color(0xFFE2E8F0),
                onChanged: (val) {
                  _updateSelectedLayer(
                    (l) => l.copyWith(opacity: val),
                    record: false,
                  );
                },
                onChangeEnd: (val) => _recordHistory(),
              ),
            ),
            Text(
              '${(selected.opacity * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Tab 2: Badge & Background ---

  Widget _buildBadgeAndBackgroundTab(TextLayer selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Background Styles Selector
        Row(
          children: [
            for (final style in TextBackgroundStyle.values) ...[
              Expanded(
                child: InkWell(
                  onTap: () => _updateSelectedLayer(
                    (l) => l.copyWith(backgroundStyle: style),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selected.backgroundStyle == style
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected.backgroundStyle == style
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          size: 16,
                          color: selected.backgroundStyle == style
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          style.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected.backgroundStyle == style
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selected.backgroundStyle == style
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (style != TextBackgroundStyle.values.last)
                const SizedBox(width: 6),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Background Color Swatches (if background is enabled)
        if (selected.backgroundStyle != TextBackgroundStyle.none)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetColors.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final color = _presetColors[index];
                      final bool isSelected =
                          selected.backgroundColor.value == color.value;

                      return GestureDetector(
                        onTap: () => _updateSelectedLayer(
                          (l) => l.copyWith(backgroundColor: color),
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFCBD5E1),
                              width: isSelected ? 2.5 : 1.2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Background Opacity
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Alpha ${(selected.backgroundOpacity * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 28,
                      child: Slider(
                        value: selected.backgroundOpacity,
                        min: 0.1,
                        max: 1.0,
                        activeColor: const Color(0xFF2563EB),
                        inactiveColor: const Color(0xFFE2E8F0),
                        onChanged: (val) {
                          _updateSelectedLayer(
                            (l) => l.copyWith(backgroundOpacity: val),
                            record: false,
                          );
                        },
                        onChangeEnd: (val) => _recordHistory(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                'Select a badge style above to customize background color',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
      ],
    );
  }

  // --- Tab 3: Effects (Stroke & Shadow & Size) ---

  Widget _buildEffectsTab(TextLayer selected) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stroke Outline Toggle & Shadow Toggle Row
          Row(
            children: [
              // Stroke Toggle
              Expanded(
                child: FilterChip(
                  label: const Text('Outline Stroke'),
                  avatar: Icon(
                    selected.hasStroke
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: selected.hasStroke
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF64748B),
                  ),
                  selected: selected.hasStroke,
                  selectedColor: const Color(0xFFEFF6FF),
                  checkmarkColor: const Color(0xFF2563EB),
                  onSelected: (val) => _updateSelectedLayer(
                    (l) => l.copyWith(hasStroke: val),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Shadow Toggle
              Expanded(
                child: FilterChip(
                  label: const Text('Drop Shadow'),
                  avatar: Icon(
                    selected.hasShadow
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: selected.hasShadow
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF64748B),
                  ),
                  selected: selected.hasShadow,
                  selectedColor: const Color(0xFFEFF6FF),
                  checkmarkColor: const Color(0xFF2563EB),
                  onSelected: (val) => _updateSelectedLayer(
                    (l) => l.copyWith(hasShadow: val),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Font Size Slider
          Row(
            children: [
              const Text(
                'Size',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              Expanded(
                child: Slider(
                  value: selected.fontSize,
                  min: 14.0,
                  max: 72.0,
                  activeColor: const Color(0xFF2563EB),
                  inactiveColor: const Color(0xFFE2E8F0),
                  onChanged: (val) {
                    _updateSelectedLayer(
                      (l) => l.copyWith(fontSize: val),
                      record: false,
                    );
                  },
                  onChangeEnd: (val) => _recordHistory(),
                ),
              ),
              Text(
                '${selected.fontSize.toInt()}pt',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Tab 4: Layers Management ---

  Widget _buildLayersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_layers.length} Total Layers',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              onPressed: () => _addNewTextLayer(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Layer'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _layers.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final layer = _layers[index];
              final bool isSelected = layer.id == _selectedLayerId;

              return Container(
                width: 140,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedLayerId = layer.id;
                        });
                      },
                      child: Text(
                        layer.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => _sendBackward(layer.id),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _bringForward(layer.id),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _deleteLayer(layer.id),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleChip({
    IconData? icon,
    String? text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  size: 16,
                  color: isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF475569),
                )
              : Text(
                  text ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF475569),
                  ),
                ),
        ),
      ),
    );
  }
}

// --- Text Edit Modal Sheet ---

class _TextEditBottomSheet extends StatefulWidget {
  final String initialText;
  final TextEditingController controller;

  const _TextEditBottomSheet({
    required this.initialText,
    required this.controller,
  });

  @override
  State<_TextEditBottomSheet> createState() => _TextEditBottomSheetState();
}

class _TextEditBottomSheetState extends State<_TextEditBottomSheet> {
  final List<String> _quickSuggestions = const [
    'Awesome',
    'Summer Vibes',
    'Memories',
    'Good Times',
    'Adventure',
    'Explore',
    'Happy Birthday',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Text',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () {
                  Navigator.of(context).pop(widget.controller.text);
                },
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Enter text here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          // Quick suggestions
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickSuggestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final suggestion = _quickSuggestions[index];
                return ActionChip(
                  label: Text(
                    suggestion,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    widget.controller.text = suggestion;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Single Layer Painter for Canvas Widget ---

class _SingleTextLayerPainter extends CustomPainter {
  final TextLayer layer;

  _SingleTextLayerPainter({required this.layer});

  @override
  void paint(Canvas canvas, Size size) {
    layer.renderLocalBox(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _SingleTextLayerPainter oldDelegate) {
    return oldDelegate.layer != layer;
  }
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
