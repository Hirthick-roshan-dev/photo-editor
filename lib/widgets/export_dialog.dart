import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/editable_image.dart';
import '../utils/export_engine.dart';

class ExportDialog extends StatefulWidget {
  final EditableImage image;

  const ExportDialog({super.key, required this.image});

  static Future<void> show(BuildContext context, EditableImage image) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportDialog(image: image),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late TextEditingController _fileNameController;

  ExportFormat _selectedFormat = ExportFormat.png;
  double _quality = 0.90; // 90%
  double _scale = 1.0; // 100%

  bool _isExporting = false;
  String _exportStatus = '';

  @override
  void initState() {
    super.initState();
    String defaultName = widget.image.name;
    final int dotIndex = defaultName.lastIndexOf('.');
    if (dotIndex != -1) {
      defaultName = defaultName.substring(0, dotIndex);
    }
    _fileNameController = TextEditingController(text: '${defaultName}_edited');
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  int get _targetWidth {
    final int origW = widget.image.width ?? 1080;
    return (origW * _scale).round();
  }

  int get _targetHeight {
    final int origH = widget.image.height ?? 1080;
    return (origH * _scale).round();
  }

  String get _estimatedSizeText {
    final int baseBytes = widget.image.fileSizeInBytes ?? widget.image.bytes.lengthInBytes;
    double factor = _scale * _scale;

    if (_selectedFormat == ExportFormat.jpeg) {
      factor *= (_quality * 0.7);
    } else if (_selectedFormat == ExportFormat.bmp) {
      factor *= 1.3;
    } else {
      factor *= 0.95;
    }

    final int estimatedBytes = (baseBytes * factor).round().clamp(1024, 500 * 1024 * 1024);
    if (estimatedBytes < 1024 * 1024) {
      return '~${(estimatedBytes / 1024).toStringAsFixed(0)} KB';
    } else {
      return '~${(estimatedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Processing image...';
    });

    try {
      final ExportResult result = await ExportEngine.processImage(
        image: widget.image,
        format: _selectedFormat,
        quality: _quality,
        scale: _scale,
        customFileName: _fileNameController.text,
      );

      setState(() {
        _exportStatus = 'Saving to storage...';
      });

      final String savedPath = await ExportEngine.saveToStorage(
        bytes: result.bytes,
        fileName: result.fileName,
      );

      if (!mounted) return;

      setState(() {
        _isExporting = false;
      });

      _showSuccessDialog(result, savedPath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Export failed: $e'),
        ),
      );
    }
  }

  Future<void> _handleShare() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Preparing for share...';
    });

    try {
      final ExportResult result = await ExportEngine.processImage(
        image: widget.image,
        format: _selectedFormat,
        quality: _quality,
        scale: _scale,
        customFileName: _fileNameController.text,
      );

      setState(() {
        _isExporting = false;
      });

      await ExportEngine.shareImage(
        bytes: result.bytes,
        fileName: result.fileName,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Share failed: $e'),
        ),
      );
    }
  }

  void _showSuccessDialog(ExportResult result, String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Image Saved!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: ${result.fileName}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resolution: ${result.resolution} • Size: ${result.formattedSize}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Copy path',
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: path));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Path copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleShare();
            },
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Drag Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export & Save Photo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Choose format, resolution, and quality',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Scrollable Options Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview & Info Card
                      _buildPreviewCard(),
                      const SizedBox(height: 18),

                      // File Name Input
                      const Text(
                        'File Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _fileNameController,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          suffixText: '.${_selectedFormat.extensionName}',
                          suffixStyle: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Format Selector
                      const Text(
                        'Format',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormatChip(
                              format: ExportFormat.png,
                              title: 'PNG',
                              subtitle: 'Lossless',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFormatChip(
                              format: ExportFormat.jpeg,
                              title: 'JPEG',
                              subtitle: 'Compact',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFormatChip(
                              format: ExportFormat.bmp,
                              title: 'BMP',
                              subtitle: 'High Quality',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Resolution / Scale Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Resolution / Scale',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${_targetWidth}x$_targetHeight px',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildScaleButton(1.0, '100% (Original)')),
                          const SizedBox(width: 6),
                          Expanded(child: _buildScaleButton(0.75, '75% (HD)')),
                          const SizedBox(width: 6),
                          Expanded(child: _buildScaleButton(0.50, '50% (Social)')),
                          const SizedBox(width: 6),
                          Expanded(child: _buildScaleButton(0.25, '25% (Small)')),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Quality Slider (For JPEG)
                      if (_selectedFormat == ExportFormat.jpeg) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quality Compression',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${(_quality * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF2563EB),
                            inactiveTrackColor: const Color(0xFFE2E8F0),
                            thumbColor: const Color(0xFF2563EB),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _quality,
                            min: 0.20,
                            max: 1.0,
                            divisions: 16,
                            onChanged: (val) {
                              setState(() => _quality = val);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    // Share Button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isExporting ? null : _handleShare,
                        icon: const Icon(
                          Icons.share_rounded,
                          size: 18,
                          color: Color(0xFF0F172A),
                        ),
                        label: const Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Save Button
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isExporting ? null : _handleSave,
                        icon: const Icon(Icons.save_alt_rounded, size: 18),
                        label: const Text(
                          'Save to Device',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Loading Overlay
          if (_isExporting)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _exportStatus,
                            style: const TextStyle(
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
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Image.memory(
                widget.image.bytes,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildMetaBadge(_selectedFormat.extensionName.toUpperCase(), const Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    _buildMetaBadge('${_targetWidth}x$_targetHeight', const Color(0xFF0284C7)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.pie_chart_outline_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      'Estimated Size: $_estimatedSizeText',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFormatChip({
    required ExportFormat format,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = _selectedFormat == format;

    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleButton(double scaleValue, String label) {
    final bool isSelected = (_scale - scaleValue).abs() < 0.01;

    return InkWell(
      onTap: () => setState(() => _scale = scaleValue),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label.split(' ')[0], // shows "100%", "75%", etc.
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
