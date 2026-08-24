import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Available drawing tool types
enum DrawToolType {
  pen,
  marker,
  neon,
  eraser,
  line,
  arrow,
  rectangle,
  circle;

  String get label {
    switch (this) {
      case DrawToolType.pen:
        return 'Pen';
      case DrawToolType.marker:
        return 'Highlighter';
      case DrawToolType.neon:
        return 'Neon';
      case DrawToolType.eraser:
        return 'Eraser';
      case DrawToolType.line:
        return 'Line';
      case DrawToolType.arrow:
        return 'Arrow';
      case DrawToolType.rectangle:
        return 'Rectangle';
      case DrawToolType.circle:
        return 'Circle';
    }
  }

  IconData get icon {
    switch (this) {
      case DrawToolType.pen:
        return Icons.edit_rounded;
      case DrawToolType.marker:
        return Icons.format_paint_rounded;
      case DrawToolType.neon:
        return Icons.flare_rounded;
      case DrawToolType.eraser:
        return Icons.auto_fix_high_rounded;
      case DrawToolType.line:
        return Icons.horizontal_rule_rounded;
      case DrawToolType.arrow:
        return Icons.arrow_outward_rounded;
      case DrawToolType.rectangle:
        return Icons.crop_din_rounded;
      case DrawToolType.circle:
        return Icons.circle_outlined;
    }
  }
}

/// Represents a single completed or in-progress drawing stroke
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final DrawToolType toolType;
  final Size canvasSize;
  final bool isFilled;

  const DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.opacity = 1.0,
    required this.toolType,
    required this.canvasSize,
    this.isFilled = false,
  });

  DrawingStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    double? opacity,
    DrawToolType? toolType,
    Size? canvasSize,
    bool? isFilled,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      toolType: toolType ?? this.toolType,
      canvasSize: canvasSize ?? this.canvasSize,
      isFilled: isFilled ?? this.isFilled,
    );
  }

  /// Renders this stroke onto a [Canvas] matching [targetSize], properly scaling all coordinates.
  void renderToCanvas(Canvas canvas, Size targetSize) {
    if (points.isEmpty) return;

    final double scaleX = canvasSize.width > 0
        ? targetSize.width / canvasSize.width
        : 1.0;
    final double scaleY = canvasSize.height > 0
        ? targetSize.height / canvasSize.height
        : 1.0;
    final double avgScale = (scaleX + scaleY) / 2.0;

    final List<Offset> scaledPoints = points
        .map((p) => Offset(p.dx * scaleX, p.dy * scaleY))
        .toList();

    final double scaledStrokeWidth = (strokeWidth * avgScale).clamp(
      1.0,
      1000.0,
    );
    final double effectiveOpacity = opacity.clamp(0.0, 1.0);
    final Color effectiveColor = color.withValues(alpha: effectiveOpacity);

    switch (toolType) {
      case DrawToolType.pen:
        final paint = Paint()
          ..color = effectiveColor
          ..strokeWidth = scaledStrokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;
        _drawSmoothPath(canvas, scaledPoints, paint);
        break;

      case DrawToolType.marker:
        final markerOpacity = (effectiveOpacity * 0.45).clamp(0.0, 1.0);
        final paint = Paint()
          ..color = color.withValues(alpha: markerOpacity)
          ..strokeWidth = scaledStrokeWidth * 1.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;
        _drawSmoothPath(canvas, scaledPoints, paint);
        break;

      case DrawToolType.neon:
        // Outer glow
        final glowOpacity = (effectiveOpacity * 0.65).clamp(0.0, 1.0);
        final glowPaint = Paint()
          ..color = color.withValues(alpha: glowOpacity)
          ..strokeWidth = scaledStrokeWidth * 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (scaledStrokeWidth * 0.6).clamp(1.0, 50.0),
          );
        _drawSmoothPath(canvas, scaledPoints, glowPaint);

        // Core bright stroke
        final corePaint = Paint()
          ..color = Colors.white.withValues(alpha: effectiveOpacity)
          ..strokeWidth = (scaledStrokeWidth * 0.45).clamp(1.0, 50.0)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;
        _drawSmoothPath(canvas, scaledPoints, corePaint);
        break;

      case DrawToolType.eraser:
        final paint = Paint()
          ..strokeWidth = scaledStrokeWidth * 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.clear
          ..isAntiAlias = true;
        _drawSmoothPath(canvas, scaledPoints, paint);
        break;

      case DrawToolType.line:
        final paint = Paint()
          ..color = effectiveColor
          ..strokeWidth = scaledStrokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;
        if (scaledPoints.length >= 2) {
          canvas.drawLine(scaledPoints.first, scaledPoints.last, paint);
        } else if (scaledPoints.isNotEmpty) {
          canvas.drawCircle(scaledPoints.first, scaledStrokeWidth / 2, paint);
        }
        break;

      case DrawToolType.arrow:
        final paint = Paint()
          ..color = effectiveColor
          ..strokeWidth = scaledStrokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;
        if (scaledPoints.length >= 2) {
          _drawArrow(
            canvas,
            scaledPoints.first,
            scaledPoints.last,
            paint,
            scaledStrokeWidth,
            avgScale,
          );
        } else if (scaledPoints.isNotEmpty) {
          canvas.drawCircle(scaledPoints.first, scaledStrokeWidth / 2, paint);
        }
        break;

      case DrawToolType.rectangle:
        final paint = Paint()
          ..color = effectiveColor
          ..strokeWidth = scaledStrokeWidth
          ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;
        if (scaledPoints.length >= 2) {
          final rect = Rect.fromPoints(scaledPoints.first, scaledPoints.last);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(4 * avgScale)),
            paint,
          );
        }
        break;

      case DrawToolType.circle:
        final paint = Paint()
          ..color = effectiveColor
          ..strokeWidth = scaledStrokeWidth
          ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;
        if (scaledPoints.length >= 2) {
          final rect = Rect.fromPoints(scaledPoints.first, scaledPoints.last);
          canvas.drawOval(rect, paint);
        }
        break;
    }
  }

  static void _drawSmoothPath(
    Canvas canvas,
    List<Offset> scaledPoints,
    Paint paint,
  ) {
    if (scaledPoints.isEmpty) return;

    if (scaledPoints.length == 1) {
      canvas.drawCircle(
        scaledPoints.first,
        (paint.strokeWidth / 2.0).clamp(0.5, 500.0),
        paint,
      );
      return;
    }

    if (scaledPoints.length == 2) {
      canvas.drawLine(scaledPoints[0], scaledPoints[1], paint);
      return;
    }

    final path = Path();
    path.moveTo(scaledPoints[0].dx, scaledPoints[0].dy);

    for (int i = 1; i < scaledPoints.length - 1; i++) {
      final p0 = scaledPoints[i];
      final p1 = scaledPoints[i + 1];
      final midX = (p0.dx + p1.dx) / 2.0;
      final midY = (p0.dy + p1.dy) / 2.0;
      path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
    }

    path.lineTo(scaledPoints.last.dx, scaledPoints.last.dy);
    canvas.drawPath(path, paint);
  }

  static void _drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double strokeWidth,
    double avgScale,
  ) {
    // Draw shaft
    canvas.drawLine(start, end, paint);

    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);
    if (distance < 1.0) return;

    final double angle = math.atan2(dy, dx);
    final double arrowLength = math.max(14.0 * avgScale, strokeWidth * 2.8);
    final double arrowAngle = 30.0 * (math.pi / 180.0);

    final Offset p1 = Offset(
      end.dx - arrowLength * math.cos(angle - arrowAngle),
      end.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    final Offset p2 = Offset(
      end.dx - arrowLength * math.cos(angle + arrowAngle),
      end.dy - arrowLength * math.sin(angle + arrowAngle),
    );

    // Draw arrowhead
    final headPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(p2.dx, p2.dy);

    canvas.drawPath(headPath, paint);
  }
}
