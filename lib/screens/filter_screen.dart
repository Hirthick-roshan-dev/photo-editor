import 'package:flutter/material.dart';
import '../models/editable_image.dart';
import '../models/filter_preset.dart';
import '../utils/image_filter_applier.dart';

class FilterScreen extends StatefulWidget {
  final EditableImage image;

  const FilterScreen({super.key, required this.image});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final TransformationController _transformationController =
      TransformationController();

  FilterPreset _selectedPreset = FilterPreset.presets.first; // Default: Original
  double _intensity = 1.0; // 0.0 to 1.0
  FilterCategory _selectedCategory = FilterCategory.all;
  bool _isComparing = false; // Hold to compare with original
  bool _isProcessing = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _resetFilter() {
    setState(() {
      _selectedPreset = FilterPreset.presets.first;
      _intensity = 1.0;
    });
  }

  List<double> get _currentMatrix {
    if (_isComparing || _selectedPreset.id == 'original') {
      return FilterPreset.identityMatrix;
    }
    return _selectedPreset.getAdjustedMatrix(_intensity);
  }

  List<FilterPreset> get _filteredPresets {
    if (_selectedCategory == FilterCategory.all) {
      return FilterPreset.presets;
    }
    return FilterPreset.presets.where((p) {
      return p.id == 'original' || p.category == _selectedCategory;
    }).toList();
  }

  Future<void> _applyAndReturn() async {
    // If original is selected or intensity is 0, return original image
    if (_selectedPreset.id == 'original' || _intensity <= 0.001) {
      Navigator.of(context).pop(widget.image);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final List<double> matrix = _selectedPreset.getAdjustedMatrix(_intensity);
      final EditableImage filtered = await ImageFilterApplier.applyFilter(
        image: widget.image,
        matrix: matrix,
        filterName: _selectedPreset.name,
      );

      if (!mounted) return;
      Navigator.of(context).pop(filtered);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Failed to apply filter: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFilterActive = _selectedPreset.id != 'original';
    final List<double> activeMatrix = _currentMatrix;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isFilterActive)
              Text(
                '${_selectedPreset.name} • ${(_intensity * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (isFilterActive)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _resetFilter,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset', style: TextStyle(fontSize: 12)),
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
              // Main Live Filter Preview Canvas
              Expanded(
                child: Stack(
                  children: [
                    // Subtle checkerboard pattern
                    Positioned.fill(
                      child: CustomPaint(painter: _LightCheckerboardPainter()),
                    ),

                    // Interactive image with color filter
                    Center(
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.3,
                        maxScale: 5.0,
                        boundaryMargin: const EdgeInsets.all(40.0),
                        child: Hero(
                          tag: 'image_${widget.image.name}',
                          child: Container(
                            margin: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(activeMatrix),
                              child: Image.memory(
                                widget.image.bytes,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Comparing Badge indicator
                    if (_isComparing)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Showing Original',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Floating Quick Actions (Compare & Reset Zoom)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Hold to Compare Button
                          if (isFilterActive) ...[
                            GestureDetector(
                              onTapDown: (_) => setState(() => _isComparing = true),
                              onTapUp: (_) => setState(() => _isComparing = false),
                              onTapCancel: () => setState(() => _isComparing = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isComparing
                                      ? const Color(0xFF2563EB)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.compare_arrows_rounded,
                                      size: 16,
                                      color: _isComparing
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Compare',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _isComparing
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Reset Zoom Button
                          FloatingActionButton.small(
                            heroTag: 'filter_reset_zoom_fab',
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F172A),
                            elevation: 2,
                            tooltip: 'Reset View',
                            onPressed: _resetZoom,
                            child: const Icon(
                              Icons.fit_screen_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Filter Controls & Carousel
              _buildBottomControlsPanel(isFilterActive),
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
                          'Applying filter...',
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

  Widget _buildBottomControlsPanel(bool isFilterActive) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Intensity Slider (Smooth animated show/hide)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isFilterActive
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.opacity_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Intensity',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          activeTrackColor: const Color(0xFF2563EB),
                          inactiveTrackColor: const Color(0xFFE2E8F0),
                          thumbColor: const Color(0xFF2563EB),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7.0,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16.0,
                          ),
                        ),
                        child: Slider(
                          value: _intensity,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            setState(() {
                              _intensity = value;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${(_intensity * 100).round()}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),

            if (isFilterActive)
              const Divider(color: Color(0xFFF1F5F9), height: 8),

            // Category Chips Row
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: FilterCategory.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final category = FilterCategory.values[index];
                  final isSelected = _selectedCategory == category;

                  return ChoiceChip(
                    label: Text(category.label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                    backgroundColor: const Color(0xFFF8FAFC),
                    selectedColor: const Color(0xFFEFF6FF),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.2 : 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Horizontal Filter Thumbnails Carousel
            SizedBox(
              height: 106,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filteredPresets.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final preset = _filteredPresets[index];
                  final isSelected = _selectedPreset.id == preset.id;

                  return _buildFilterThumbnailItem(
                    preset: preset,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedPreset = preset;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterThumbnailItem({
    required FilterPreset preset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail container
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9.5),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(preset.matrix),
                    child: Image.memory(
                      widget.image.bytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Filter Name Label
          SizedBox(
            width: 72,
            child: Text(
              preset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
