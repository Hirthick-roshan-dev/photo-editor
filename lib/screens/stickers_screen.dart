import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/editable_image.dart';
import '../models/sticker_layer.dart';
import '../utils/image_sticker_applier.dart';

class StickersScreen extends StatefulWidget {
  final EditableImage image;

  const StickersScreen({super.key, required this.image});

  @override
  State<StickersScreen> createState() => _StickersScreenState();
}

class _StickersScreenState extends State<StickersScreen> {
  final TransformationController _transformationController =
      TransformationController();

  // Active layers and selection
  List<StickerLayer> _layers = [];
  String? _selectedLayerId;

  // History for Undo / Redo
  final List<List<StickerLayer>> _undoHistory = [];
  final List<List<StickerLayer>> _redoHistory = [];

  // Modes & UI state
  bool _isPanZoomMode = false;
  bool _isProcessing = false;
  int _activeBottomTab = 0; // 0: Catalog, 1: Transform, 2: Opacity/Effects, 3: Layers
  String _selectedCategoryId = 'popular';

  Size _currentDisplaySize = const Size(400, 400);

  // Gesture scaling & rotating tracker for selected layer
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _initialTouchPos = Offset.zero;
  Offset _initialLayerPos = Offset.zero;

  // Curated tint colors
  static const List<Color> _presetTintColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFFACC15), // Yellow
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF0F172A), // Dark Slate
    Color(0xFFFFFFFF), // White
  ];

  @override
  void initState() {
    super.initState();
    // Default: start with an initial fun sticker centered on the canvas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _layers.isEmpty) {
        _addSticker(
          StickerCatalogItem.catalog.firstWhere((s) => s.id == 'pop_fire'),
        );
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

  StickerLayer? get _selectedLayer {
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

  void _addSticker(StickerCatalogItem item) {
    _recordHistory();
    final String newId =
        'sticker_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
    final Offset center = Offset(
      _currentDisplaySize.width / 2,
      _currentDisplaySize.height / 2,
    );

    final newLayer = StickerLayer(
      id: newId,
      type: item.type,
      content: item.content,
      icon: item.icon,
      position: center,
      size: item.type == StickerType.emoji ? 68.0 : 54.0,
      scale: 1.0,
      rotation: 0.0,
      opacity: 1.0,
      tintColor: const Color(0xFF2563EB),
      hasShadow: true,
      shadowColor: const Color(0x66000000),
      shadowBlurRadius: 4.0,
      canvasSize: _currentDisplaySize,
    );

    setState(() {
      _layers.add(newLayer);
      _selectedLayerId = newId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
        content: Row(
          children: [
            const Icon(
              Icons.emoji_emotions_outlined,
              color: Color(0xFF38BDF8),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              item.type == StickerType.emoji
                  ? 'Added ${item.content} sticker'
                  : 'Added badge sticker',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSelectedLayer(
    StickerLayer Function(StickerLayer) updater, {
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
        'sticker_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
    final duplicated = original.copyWith(
      id: newId,
      position: Offset(
        (original.position.dx + 24).clamp(24.0, _currentDisplaySize.width - 24),
        (original.position.dy + 24).clamp(24.0, _currentDisplaySize.height - 24),
      ),
    );

    setState(() {
      _layers.add(duplicated);
      _selectedLayerId = newId;
    });
  }

  void _flipHorizontal(String id) {
    final index = _layers.indexWhere((l) => l.id == id);
    if (index != -1) {
      _recordHistory();
      setState(() {
        _layers[index] = _layers[index].copyWith(
          isFlippedH: !_layers[index].isFlippedH,
        );
      });
    }
  }

  void _flipVertical(String id) {
    final index = _layers.indexWhere((l) => l.id == id);
    if (index != -1) {
      _recordHistory();
      setState(() {
        _layers[index] = _layers[index].copyWith(
          isFlippedV: !_layers[index].isFlippedV,
        );
      });
    }
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

  Future<void> _applyAndReturn() async {
    if (_layers.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final List<StickerLayer> normalizedLayers = _layers.map((layer) {
        return layer.copyWith(canvasSize: _currentDisplaySize);
      }).toList();

      final EditableImage renderedImage =
          await ImageStickerApplier.applyStickerLayers(
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
          content: Text('Failed to apply stickers: $e'),
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
                  title: const Text('Discard stickers?'),
                  content: const Text(
                    'Are you sure you want to discard your sticker additions?',
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
              'Stickers',
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
                        : Icons.emoji_emotions_outlined,
                    size: 13,
                    color: _isPanZoomMode
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPanZoomMode
                        ? 'Pan & Zoom'
                        : '${_layers.length} ${_layers.length == 1 ? "sticker" : "stickers"}',
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
              _isPanZoomMode
                  ? Icons.emoji_emotions_outlined
                  : Icons.pan_tool_rounded,
              size: 20,
              color: _isPanZoomMode
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF475569),
            ),
            tooltip: _isPanZoomMode
                ? 'Switch to Sticker Editing'
                : 'Pan & Zoom Canvas',
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

                                // Interactive Sticker Layers
                                for (final layer in _layers)
                                  _buildInteractiveStickerLayer(
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

                // Floating Actions on Canvas
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'sticker_reset_zoom_fab',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 3,
                        tooltip: 'Reset Pan & Zoom',
                        onPressed: _resetZoom,
                        child: const Icon(Icons.fit_screen_rounded, size: 18),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.extended(
                        heroTag: 'add_sticker_fab',
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        onPressed: () {
                          setState(() {
                            _activeBottomTab = 0;
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Add Sticker',
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

  // --- Interactive Sticker Widget & Handles ---

  Widget _buildInteractiveStickerLayer(
    StickerLayer layer,
    Size canvasSize, {
    required bool isSelected,
  }) {
    final Size measured = layer.measureSize();
    final double boxW = measured.width + 16.0;
    final double boxH = measured.height + 16.0;

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
              // Sticker Graphics
              CustomPaint(
                size: Size(boxW, boxH),
                painter: _SingleStickerPainter(layer: layer),
              ),

              // Active Selection Frame & Corner Handles
              if (isSelected && !_isPanZoomMode) ...[
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF2563EB),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Top-Left: Flip Horizontal
                Positioned(
                  top: -14,
                  left: -14,
                  child: _buildHandleButton(
                    icon: Icons.flip_rounded,
                    color: const Color(0xFF2563EB),
                    tooltip: 'Flip Horizontal',
                    onTap: () => _flipHorizontal(layer.id),
                  ),
                ),

                // Top-Right: Delete handle
                Positioned(
                  top: -14,
                  right: -14,
                  child: _buildHandleButton(
                    icon: Icons.close_rounded,
                    color: const Color(0xFFEF4444),
                    tooltip: 'Delete',
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

                // Bottom-Right: Resize & Rotate handle
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
                      final double delta = (d.delta.dx + d.delta.dy) / 80.0;
                      final double newScale =
                          (layer.scale + delta).clamp(0.25, 4.5);
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

  // --- Bottom Control Panel with 4 Tabs ---

  Widget _buildBottomControlPanel(StickerLayer? selected) {
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
              height: 155,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _buildTabBody(selected),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // Tab Bar Navigation
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  _buildTabButton(
                    index: 0,
                    icon: Icons.emoji_emotions_outlined,
                    label: 'Catalog',
                  ),
                  _buildTabButton(
                    index: 1,
                    icon: Icons.transform_rounded,
                    label: 'Transform',
                  ),
                  _buildTabButton(
                    index: 2,
                    icon: Icons.auto_fix_high_rounded,
                    label: 'Effects',
                  ),
                  _buildTabButton(
                    index: 3,
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

  Widget _buildTabBody(StickerLayer? selected) {
    if (_activeBottomTab == 0) {
      return _buildCatalogTab();
    } else if (selected == null) {
      return _buildNoSelectionTab();
    }

    switch (_activeBottomTab) {
      case 1:
        return _buildTransformTab(selected);
      case 2:
        return _buildEffectsTab(selected);
      case 3:
        return _buildLayersTab();
      default:
        return const SizedBox.shrink();
    }
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
            'Select a sticker on canvas or choose from the catalog',
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
            onPressed: () {
              setState(() {
                _activeBottomTab = 0;
              });
            },
            icon: const Icon(Icons.emoji_emotions_outlined, size: 16),
            label: const Text('Open Catalog'),
          ),
        ],
      ),
    );
  }

  // --- Tab 0: Sticker Catalog ---

  Widget _buildCatalogTab() {
    final filteredItems = StickerCatalogItem.catalog
        .where((s) => s.categoryId == _selectedCategoryId)
        .toList();

    return Column(
      children: [
        // Category Chips Row
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: StickerCategory.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final cat = StickerCategory.categories[index];
              final bool isSelected = _selectedCategoryId == cat.id;

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 14,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 4),
                    Text(cat.label, style: const TextStyle(fontSize: 11)),
                  ],
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF2563EB),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedCategoryId = cat.id;
                    });
                  }
                },
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Sticker Items Horizontal Grid
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filteredItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = filteredItems[index];

              return InkWell(
                onTap: () => _addSticker(item),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: item.type == StickerType.emoji
                        ? Text(
                            item.content,
                            style: const TextStyle(fontSize: 34),
                          )
                        : Icon(
                            item.icon,
                            size: 34,
                            color: const Color(0xFF2563EB),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Tab 1: Transform & Flip ---

  Widget _buildTransformTab(StickerLayer selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Flip Actions + Snaps
        Row(
          children: [
            // Flip Horizontal
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: selected.isFlippedH
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                  ),
                  backgroundColor: selected.isFlippedH
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                ),
                onPressed: () => _flipHorizontal(selected.id),
                icon: const Icon(Icons.flip_rounded, size: 16),
                label: const Text('Flip H', style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 6),

            // Flip Vertical
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: selected.isFlippedV
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                  ),
                  backgroundColor: selected.isFlippedV
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                ),
                onPressed: () => _flipVertical(selected.id),
                icon: const Icon(Icons.swap_vert_rounded, size: 16),
                label: const Text('Flip V', style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 6),

            // Snap 0 deg
            _buildSnapButton('0°', () {
              _updateSelectedLayer((l) => l.copyWith(rotation: 0.0));
            }),
            const SizedBox(width: 4),
            // Snap 90 deg
            _buildSnapButton('90°', () {
              _updateSelectedLayer(
                (l) => l.copyWith(rotation: math.pi / 2.0),
              );
            }),
          ],
        ),

        const SizedBox(height: 8),

        // Size Slider
        Row(
          children: [
            const Text(
              'Scale',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            Expanded(
              child: Slider(
                value: selected.scale,
                min: 0.3,
                max: 3.5,
                activeColor: const Color(0xFF2563EB),
                inactiveColor: const Color(0xFFE2E8F0),
                onChanged: (val) {
                  _updateSelectedLayer(
                    (l) => l.copyWith(scale: val),
                    record: false,
                  );
                },
                onChangeEnd: (val) => _recordHistory(),
              ),
            ),
            Text(
              '${(selected.scale * 100).toInt()}%',
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

  Widget _buildSnapButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // --- Tab 2: Opacity & Effects ---

  Widget _buildEffectsTab(StickerLayer selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drop Shadow Toggle & Tint Swatches Row
        Row(
          children: [
            FilterChip(
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
            const SizedBox(width: 8),

            // Tint Palette (if icon badge)
            if (selected.type == StickerType.iconBadge)
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetTintColors.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final color = _presetTintColors[index];
                      final bool isSelected =
                          selected.tintColor?.value == color.value;

                      return GestureDetector(
                        onTap: () => _updateSelectedLayer(
                          (l) => l.copyWith(tintColor: color),
                        ),
                        child: Container(
                          width: 28,
                          height: 28,
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
              ),
          ],
        ),

        const SizedBox(height: 6),

        // Opacity Slider
        Row(
          children: [
            const Text(
              'Opacity',
              style: TextStyle(
                fontSize: 11.5,
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

  // --- Tab 3: Layers Management ---

  Widget _buildLayersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_layers.length} Total Stickers',
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
              onPressed: () {
                setState(() {
                  _activeBottomTab = 0;
                });
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Sticker'),
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
                width: 120,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedLayerId = layer.id;
                        });
                      },
                      child: layer.type == StickerType.emoji
                          ? Text(
                              layer.content,
                              style: const TextStyle(fontSize: 24),
                            )
                          : Icon(
                              layer.icon,
                              size: 24,
                              color: layer.tintColor ?? const Color(0xFF2563EB),
                            ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
}

// --- Single Sticker Painter for Canvas Widget ---

class _SingleStickerPainter extends CustomPainter {
  final StickerLayer layer;

  _SingleStickerPainter({required this.layer});

  @override
  void paint(Canvas canvas, Size size) {
    layer.renderLocalBox(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _SingleStickerPainter oldDelegate) {
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
