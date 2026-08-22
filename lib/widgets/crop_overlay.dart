import 'package:flutter/material.dart';

enum CropHandleType {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  inside,
  none,
}

class CropOverlay extends StatefulWidget {
  final Size imageDisplaySize;
  final Rect initialCropRect;
  final double? fixedAspectRatio; // null means Free Crop
  final ValueChanged<Rect> onCropRectChanged;

  const CropOverlay({
    super.key,
    required this.imageDisplaySize,
    required this.initialCropRect,
    this.fixedAspectRatio,
    required this.onCropRectChanged,
  });

  @override
  State<CropOverlay> createState() => CropOverlayState();
}

class CropOverlayState extends State<CropOverlay> {
  late Rect _cropRect;
  CropHandleType _activeHandle = CropHandleType.none;
  Offset? _lastPanPosition;

  static const double _minSize = 40.0;
  static const double _handleTouchSize = 44.0;

  @override
  void initState() {
    super.initState();
    _cropRect = widget.initialCropRect;
    _clampCropRect();
  }

  @override
  void didUpdateWidget(covariant CropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageDisplaySize != oldWidget.imageDisplaySize) {
      _clampCropRect();
    }
    if (widget.fixedAspectRatio != oldWidget.fixedAspectRatio &&
        widget.fixedAspectRatio != null) {
      _applyAspectRatio(widget.fixedAspectRatio!);
    }
  }

  void _clampCropRect() {
    final double maxW = widget.imageDisplaySize.width;
    final double maxH = widget.imageDisplaySize.height;

    double left = _cropRect.left.clamp(0.0, maxW - _minSize);
    double top = _cropRect.top.clamp(0.0, maxH - _minSize);
    double width = _cropRect.width.clamp(_minSize, maxW - left);
    double height = _cropRect.height.clamp(_minSize, maxH - top);

    _cropRect = Rect.fromLTWH(left, top, width, height);
  }

  void _applyAspectRatio(double ratio) {
    final double maxW = widget.imageDisplaySize.width;
    final double maxH = widget.imageDisplaySize.height;

    double newW = _cropRect.width;
    double newH = newW / ratio;

    if (newH > maxH) {
      newH = maxH;
      newW = newH * ratio;
    }
    if (newW > maxW) {
      newW = maxW;
      newH = newW / ratio;
    }

    final Offset center = _cropRect.center;
    double newLeft = center.dx - newW / 2;
    double newTop = center.dy - newH / 2;

    if (newLeft < 0) newLeft = 0;
    if (newTop < 0) newTop = 0;
    if (newLeft + newW > maxW) newLeft = maxW - newW;
    if (newTop + newH > maxH) newTop = maxH - newH;

    setState(() {
      _cropRect = Rect.fromLTWH(newLeft, newTop, newW, newH);
    });
    widget.onCropRectChanged(_cropRect);
  }

  void resetToFull() {
    setState(() {
      _cropRect = Rect.fromLTWH(
        0,
        0,
        widget.imageDisplaySize.width,
        widget.imageDisplaySize.height,
      );
    });
    widget.onCropRectChanged(_cropRect);
  }

  void setAspectRatio(double? ratio) {
    if (ratio == null) {
      // Free crop, keep current crop rect
      return;
    }
    _applyAspectRatio(ratio);
  }

  CropHandleType _hitTestHandle(Offset localPosition) {
    final double l = _cropRect.left;
    final double t = _cropRect.top;
    final double r = _cropRect.right;
    final double b = _cropRect.bottom;
    final double cx = _cropRect.center.dx;
    final double cy = _cropRect.center.dy;

    const double hitRadius = _handleTouchSize / 2;

    // Corner Handles
    if ((localPosition - Offset(l, t)).distance <= hitRadius) {
      return CropHandleType.topLeft;
    }
    if ((localPosition - Offset(r, t)).distance <= hitRadius) {
      return CropHandleType.topRight;
    }
    if ((localPosition - Offset(l, b)).distance <= hitRadius) {
      return CropHandleType.bottomLeft;
    }
    if ((localPosition - Offset(r, b)).distance <= hitRadius) {
      return CropHandleType.bottomRight;
    }

    // Edge Center Handles
    if ((localPosition - Offset(cx, t)).distance <= hitRadius) {
      return CropHandleType.topCenter;
    }
    if ((localPosition - Offset(cx, b)).distance <= hitRadius) {
      return CropHandleType.bottomCenter;
    }
    if ((localPosition - Offset(l, cy)).distance <= hitRadius) {
      return CropHandleType.centerLeft;
    }
    if ((localPosition - Offset(r, cy)).distance <= hitRadius) {
      return CropHandleType.centerRight;
    }

    // Inside Area (move crop window)
    if (_cropRect.contains(localPosition)) {
      return CropHandleType.inside;
    }

    return CropHandleType.none;
  }

  MouseCursor _cursorForHandle(CropHandleType handle) {
    switch (handle) {
      case CropHandleType.topLeft:
      case CropHandleType.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case CropHandleType.topRight:
      case CropHandleType.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case CropHandleType.topCenter:
      case CropHandleType.bottomCenter:
        return SystemMouseCursors.resizeUpDown;
      case CropHandleType.centerLeft:
      case CropHandleType.centerRight:
        return SystemMouseCursors.resizeLeftRight;
      case CropHandleType.inside:
        return SystemMouseCursors.move;
      case CropHandleType.none:
        return SystemMouseCursors.basic;
    }
  }

  void _onPanStart(DragStartDetails details) {
    final handle = _hitTestHandle(details.localPosition);
    if (handle != CropHandleType.none) {
      setState(() {
        _activeHandle = handle;
        _lastPanPosition = details.localPosition;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeHandle == CropHandleType.none || _lastPanPosition == null) return;

    final Offset delta = details.localPosition - _lastPanPosition!;
    _lastPanPosition = details.localPosition;

    final double maxW = widget.imageDisplaySize.width;
    final double maxH = widget.imageDisplaySize.height;

    double l = _cropRect.left;
    double t = _cropRect.top;
    double r = _cropRect.right;
    double b = _cropRect.bottom;

    if (_activeHandle == CropHandleType.inside) {
      // Pan / Move crop box
      double dx = delta.dx;
      double dy = delta.dy;

      if (l + dx < 0) dx = -l;
      if (r + dx > maxW) dx = maxW - r;
      if (t + dy < 0) dy = -t;
      if (b + dy > maxH) dy = maxH - b;

      l += dx;
      r += dx;
      t += dy;
      b += dy;
    } else {
      // Resize with handles
      final double? ratio = widget.fixedAspectRatio;

      if (ratio == null) {
        // Free Crop resizing for each of the 8 handles
        switch (_activeHandle) {
          case CropHandleType.topLeft:
            l = (l + delta.dx).clamp(0.0, r - _minSize);
            t = (t + delta.dy).clamp(0.0, b - _minSize);
            break;
          case CropHandleType.topCenter:
            t = (t + delta.dy).clamp(0.0, b - _minSize);
            break;
          case CropHandleType.topRight:
            r = (r + delta.dx).clamp(l + _minSize, maxW);
            t = (t + delta.dy).clamp(0.0, b - _minSize);
            break;
          case CropHandleType.centerLeft:
            l = (l + delta.dx).clamp(0.0, r - _minSize);
            break;
          case CropHandleType.centerRight:
            r = (r + delta.dx).clamp(l + _minSize, maxW);
            break;
          case CropHandleType.bottomLeft:
            l = (l + delta.dx).clamp(0.0, r - _minSize);
            b = (b + delta.dy).clamp(t + _minSize, maxH);
            break;
          case CropHandleType.bottomCenter:
            b = (b + delta.dy).clamp(t + _minSize, maxH);
            break;
          case CropHandleType.bottomRight:
            r = (r + delta.dx).clamp(l + _minSize, maxW);
            b = (b + delta.dy).clamp(t + _minSize, maxH);
            break;
          default:
            break;
        }
      } else {
        // Fixed Aspect Ratio Resizing
        switch (_activeHandle) {
          case CropHandleType.topLeft:
          case CropHandleType.topCenter:
          case CropHandleType.centerLeft:
            double newW = (r - (l + delta.dx)).clamp(_minSize, r);
            double newH = newW / ratio;
            if (b - newH < 0) {
              newH = b;
              newW = newH * ratio;
            }
            l = r - newW;
            t = b - newH;
            break;
          case CropHandleType.topRight:
            double newW = ((r + delta.dx) - l).clamp(_minSize, maxW - l);
            double newH = newW / ratio;
            if (b - newH < 0) {
              newH = b;
              newW = newH * ratio;
            }
            r = l + newW;
            t = b - newH;
            break;
          case CropHandleType.bottomLeft:
            double newW = (r - (l + delta.dx)).clamp(_minSize, r);
            double newH = newW / ratio;
            if (t + newH > maxH) {
              newH = maxH - t;
              newW = newH * ratio;
            }
            l = r - newW;
            b = t + newH;
            break;
          case CropHandleType.bottomRight:
          case CropHandleType.bottomCenter:
          case CropHandleType.centerRight:
            double newW = ((r + delta.dx) - l).clamp(_minSize, maxW - l);
            double newH = newW / ratio;
            if (t + newH > maxH) {
              newH = maxH - t;
              newW = newH * ratio;
            }
            r = l + newW;
            b = t + newH;
            break;
          default:
            break;
        }
      }
    }

    setState(() {
      _cropRect = Rect.fromLTRB(l, t, r, b);
    });
    widget.onCropRectChanged(_cropRect);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _activeHandle = CropHandleType.none;
      _lastPanPosition = null;
    });
  }

  void _onPanCancel() {
    setState(() {
      _activeHandle = CropHandleType.none;
      _lastPanPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _cursorForHandle(_activeHandle),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        child: CustomPaint(
          size: widget.imageDisplaySize,
          painter: _CropPainter(
            cropRect: _cropRect,
            imageSize: widget.imageDisplaySize,
          ),
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final Rect cropRect;
  final Size imageSize;

  _CropPainter({
    required this.cropRect,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Dark mask overlay outside the crop rectangle
    final Paint maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.58)
      ..style = PaintingStyle.fill;

    final Path maskPath = Path()
      ..addRect(fullRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(maskPath, maskPaint);

    // 2. Crop border outline (crisp white line)
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    canvas.drawRect(cropRect, borderPaint);

    // 3. Rule of Thirds 3x3 Grid Lines
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double oneThirdW = cropRect.width / 3.0;
    final double oneThirdH = cropRect.height / 3.0;

    // Vertical lines
    canvas.drawLine(
      Offset(cropRect.left + oneThirdW, cropRect.top),
      Offset(cropRect.left + oneThirdW, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + oneThirdW * 2, cropRect.top),
      Offset(cropRect.left + oneThirdW * 2, cropRect.bottom),
      gridPaint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + oneThirdH),
      Offset(cropRect.right, cropRect.top + oneThirdH),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + oneThirdH * 2),
      Offset(cropRect.right, cropRect.top + oneThirdH * 2),
      gridPaint,
    );

    // 4. Draw 8 Control Points:
    // 4 Corner brackets + 4 Center line/dot handles
    _drawCornerHandles(canvas, cropRect);
    _drawEdgeCenterHandles(canvas, cropRect);
  }

  void _drawCornerHandles(Canvas canvas, Rect rect) {
    const double cornerLength = 22.0;
    const double cornerThickness = 4.0;

    final Paint cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = cornerThickness
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final Paint cornerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = cornerThickness + 1.5
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    void drawL(Offset corner, Offset armH, Offset armV) {
      final Path path = Path()
        ..moveTo(armH.dx, armH.dy)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(armV.dx, armV.dy);

      canvas.drawPath(path, cornerShadowPaint);
      canvas.drawPath(path, cornerPaint);
    }

    // Top-Left
    drawL(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      Offset(rect.left, rect.top + cornerLength),
    );

    // Top-Right
    drawL(
      Offset(rect.right, rect.top),
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top + cornerLength),
    );

    // Bottom-Left
    drawL(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      Offset(rect.left, rect.bottom - cornerLength),
    );

    // Bottom-Right
    drawL(
      Offset(rect.right, rect.bottom),
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
    );
  }

  void _drawEdgeCenterHandles(Canvas canvas, Rect rect) {
    const double handleLength = 24.0;
    const double handleThickness = 4.0;

    final Paint handlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = handleThickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint handleShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = handleThickness + 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint dotPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final Paint dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double cx = rect.center.dx;
    final double cy = rect.center.dy;

    // Helper to draw horizontal center edge handle
    void drawHBar(Offset center) {
      final p1 = Offset(center.dx - handleLength / 2, center.dy);
      final p2 = Offset(center.dx + handleLength / 2, center.dy);
      canvas.drawLine(p1, p2, handleShadowPaint);
      canvas.drawLine(p1, p2, handlePaint);

      // Center dot badge
      canvas.drawCircle(center, 4.0, dotPaint);
      canvas.drawCircle(center, 4.0, dotBorderPaint);
    }

    // Helper to draw vertical center edge handle
    void drawVBar(Offset center) {
      final p1 = Offset(center.dx, center.dy - handleLength / 2);
      final p2 = Offset(center.dx, center.dy + handleLength / 2);
      canvas.drawLine(p1, p2, handleShadowPaint);
      canvas.drawLine(p1, p2, handlePaint);

      // Center dot badge
      canvas.drawCircle(center, 4.0, dotPaint);
      canvas.drawCircle(center, 4.0, dotBorderPaint);
    }

    // Top Center
    drawHBar(Offset(cx, rect.top));

    // Bottom Center
    drawHBar(Offset(cx, rect.bottom));

    // Left Center
    drawVBar(Offset(rect.left, cy));

    // Right Center
    drawVBar(Offset(rect.right, cy));
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.imageSize != imageSize;
  }
}
