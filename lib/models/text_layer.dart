import 'package:flutter/material.dart';

/// Style of text background / badge
enum TextBackgroundStyle {
  none,
  filledBox,
  roundedPill,
  outlineBox;

  String get label {
    switch (this) {
      case TextBackgroundStyle.none:
        return 'None';
      case TextBackgroundStyle.filledBox:
        return 'Box';
      case TextBackgroundStyle.roundedPill:
        return 'Badge';
      case TextBackgroundStyle.outlineBox:
        return 'Outline';
    }
  }

  IconData get icon {
    switch (this) {
      case TextBackgroundStyle.none:
        return Icons.block_rounded;
      case TextBackgroundStyle.filledBox:
        return Icons.crop_square_rounded;
      case TextBackgroundStyle.roundedPill:
        return Icons.strikethrough_s_rounded;
      case TextBackgroundStyle.outlineBox:
        return Icons.check_box_outline_blank_rounded;
    }
  }
}

/// Predefined curated typography presets
class TextFontPreset {
  final String id;
  final String label;
  final String? fontFamily;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final double letterSpacing;

  const TextFontPreset({
    required this.id,
    required this.label,
    this.fontFamily,
    this.fontWeight = FontWeight.w600,
    this.fontStyle = FontStyle.normal,
    this.letterSpacing = 0.0,
  });

  static const List<TextFontPreset> presets = [
    TextFontPreset(
      id: 'modern',
      label: 'Modern',
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    TextFontPreset(
      id: 'bold_impact',
      label: 'Impact',
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
    ),
    TextFontPreset(
      id: 'elegant',
      label: 'Serif',
      fontFamily: 'serif',
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    TextFontPreset(
      id: 'monospace',
      label: 'Mono',
      fontFamily: 'monospace',
      fontWeight: FontWeight.w500,
      letterSpacing: 0.0,
    ),
    TextFontPreset(
      id: 'italic_style',
      label: 'Italic',
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      letterSpacing: 0.2,
    ),
    TextFontPreset(
      id: 'clean_light',
      label: 'Light',
      fontWeight: FontWeight.w300,
      letterSpacing: 1.5,
    ),
  ];
}

/// Represents a single text layer placed on the canvas
class TextLayer {
  final String id;
  final String text;
  final Offset position; // Center point on canvas
  final double fontSize;
  final double scale;
  final double rotation; // Radians
  final Color color;
  final double opacity;
  final String? fontFamily;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final TextAlign textAlign;
  final double letterSpacing;
  final double lineHeight;
  final bool isUppercase;
  final TextBackgroundStyle backgroundStyle;
  final Color backgroundColor;
  final double backgroundOpacity;
  final double backgroundPadding;
  final double backgroundBorderRadius;
  final bool hasStroke;
  final Color strokeColor;
  final double strokeWidth;
  final bool hasShadow;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final Size canvasSize;

  const TextLayer({
    required this.id,
    required this.text,
    required this.position,
    this.fontSize = 32.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = const Color(0xFFFFFFFF),
    this.opacity = 1.0,
    this.fontFamily,
    this.fontWeight = FontWeight.w700,
    this.fontStyle = FontStyle.normal,
    this.textAlign = TextAlign.center,
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.isUppercase = false,
    this.backgroundStyle = TextBackgroundStyle.none,
    this.backgroundColor = const Color(0xFF0F172A),
    this.backgroundOpacity = 0.75,
    this.backgroundPadding = 12.0,
    this.backgroundBorderRadius = 8.0,
    this.hasStroke = false,
    this.strokeColor = const Color(0xFF0F172A),
    this.strokeWidth = 2.0,
    this.hasShadow = true,
    this.shadowColor = const Color(0x99000000),
    this.shadowBlurRadius = 4.0,
    this.shadowOffset = const Offset(1.5, 1.5),
    required this.canvasSize,
  });

  String get displayText => isUppercase ? text.toUpperCase() : text;

  TextLayer copyWith({
    String? id,
    String? text,
    Offset? position,
    double? fontSize,
    double? scale,
    double? rotation,
    Color? color,
    double? opacity,
    String? fontFamily,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextAlign? textAlign,
    double? letterSpacing,
    double? lineHeight,
    bool? isUppercase,
    TextBackgroundStyle? backgroundStyle,
    Color? backgroundColor,
    double? backgroundOpacity,
    double? backgroundPadding,
    double? backgroundBorderRadius,
    bool? hasStroke,
    Color? strokeColor,
    double? strokeWidth,
    bool? hasShadow,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    Size? canvasSize,
  }) {
    return TextLayer(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      fontSize: fontSize ?? this.fontSize,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      textAlign: textAlign ?? this.textAlign,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      isUppercase: isUppercase ?? this.isUppercase,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      backgroundPadding: backgroundPadding ?? this.backgroundPadding,
      backgroundBorderRadius:
          backgroundBorderRadius ?? this.backgroundBorderRadius,
      hasStroke: hasStroke ?? this.hasStroke,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      canvasSize: canvasSize ?? this.canvasSize,
    );
  }

  /// Measures the layout size of this text layer at the given [avgScale].
  Size measureSize({double avgScale = 1.0}) {
    final double effectiveFontSize = (fontSize * scale * avgScale).clamp(
      8.0,
      1000.0,
    );
    final textSpan = TextSpan(
      text: displayText,
      style: TextStyle(
        fontSize: effectiveFontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing * avgScale,
        height: lineHeight,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return Size(textPainter.width, textPainter.height);
  }

  /// Renders this text layer onto a [Canvas] matching [targetSize] with exact transforms.
  void renderToCanvas(Canvas canvas, Size targetSize) {
    if (text.isEmpty) return;

    final double scaleX = canvasSize.width > 0
        ? targetSize.width / canvasSize.width
        : 1.0;
    final double scaleY = canvasSize.height > 0
        ? targetSize.height / canvasSize.height
        : 1.0;
    final double avgScale = (scaleX + scaleY) / 2.0;

    final Offset scaledCenter = Offset(
      position.dx * scaleX,
      position.dy * scaleY,
    );
    final double effectiveFontSize = (fontSize * scale * avgScale).clamp(
      4.0,
      1200.0,
    );
    final double scaledPadding = backgroundPadding * avgScale;
    final double scaledBorderRadius = backgroundBorderRadius * avgScale;

    // Create TextPainter
    final TextStyle baseStyle = TextStyle(
      fontSize: effectiveFontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing * avgScale,
      height: lineHeight,
    );

    final TextPainter painter = TextPainter(
      text: TextSpan(text: displayText, style: baseStyle),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    painter.layout();

    final double textW = painter.width;
    final double textH = painter.height;

    canvas.save();
    canvas.translate(scaledCenter.dx, scaledCenter.dy);
    canvas.rotate(rotation);

    final Rect bgRect = Rect.fromCenter(
      center: Offset.zero,
      width: textW + scaledPadding * 2,
      height: textH + scaledPadding * 1.4,
    );

    // 1. Draw background badge / box if enabled
    if (backgroundStyle != TextBackgroundStyle.none) {
      final Color effectiveBgColor = backgroundColor.withValues(
        alpha: (backgroundOpacity * opacity).clamp(0.0, 1.0),
      );

      switch (backgroundStyle) {
        case TextBackgroundStyle.filledBox:
          final Paint bgPaint = Paint()
            ..color = effectiveBgColor
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              bgRect,
              Radius.circular(scaledBorderRadius),
            ),
            bgPaint,
          );
          break;

        case TextBackgroundStyle.roundedPill:
          final Paint pillPaint = Paint()
            ..color = effectiveBgColor
            ..style = PaintingStyle.fill;
          final double pillRadius = bgRect.height / 2.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(bgRect, Radius.circular(pillRadius)),
            pillPaint,
          );
          break;

        case TextBackgroundStyle.outlineBox:
          final Paint outlinePaint = Paint()
            ..color = effectiveBgColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = (2.0 * avgScale).clamp(1.0, 40.0);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              bgRect,
              Radius.circular(scaledBorderRadius),
            ),
            outlinePaint,
          );
          break;

        case TextBackgroundStyle.none:
          break;
      }
    }

    final Offset textOffset = Offset(-textW / 2, -textH / 2);

    // 2. Draw Stroke Outline if enabled
    if (hasStroke && strokeWidth > 0) {
      final double scaledStrokeWidth = (strokeWidth * avgScale).clamp(
        0.5,
        100.0,
      );
      final TextPainter strokePainter = TextPainter(
        text: TextSpan(
          text: displayText,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = scaledStrokeWidth * 2.0
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor.withValues(
                alpha: opacity.clamp(0.0, 1.0),
              ),
          ),
        ),
        textAlign: textAlign,
        textDirection: TextDirection.ltr,
      );
      strokePainter.layout();
      strokePainter.paint(canvas, textOffset);
    }

    // 3. Draw Main Text (with optional shadow)
    final List<Shadow> shadows = [];
    if (hasShadow && shadowBlurRadius > 0) {
      shadows.add(
        Shadow(
          color: shadowColor.withValues(
            alpha: (shadowColor.a * opacity).clamp(0.0, 1.0),
          ),
          blurRadius: (shadowBlurRadius * avgScale).clamp(0.0, 100.0),
          offset: Offset(
            shadowOffset.dx * avgScale,
            shadowOffset.dy * avgScale,
          ),
        ),
      );
    }

    final TextPainter fillPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: baseStyle.copyWith(
          color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
          shadows: shadows,
        ),
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    fillPainter.layout();
    fillPainter.paint(canvas, textOffset);

    canvas.restore();
  }

  /// Renders this text layer inside a local widget box of [boxSize] centered at (boxSize.width/2, boxSize.height/2).
  void renderLocalBox(Canvas canvas, Size boxSize) {
    if (text.isEmpty) return;

    final double effectiveFontSize = (fontSize * scale).clamp(4.0, 1200.0);
    final double pad = backgroundPadding;
    final double borderRadius = backgroundBorderRadius;

    final TextStyle baseStyle = TextStyle(
      fontSize: effectiveFontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );

    final TextPainter painter = TextPainter(
      text: TextSpan(text: displayText, style: baseStyle),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    painter.layout();

    final double textW = painter.width;
    final double textH = painter.height;

    final Rect bgRect = Rect.fromCenter(
      center: Offset(boxSize.width / 2, boxSize.height / 2),
      width: textW + pad * 2,
      height: textH + pad * 1.4,
    );

    // 1. Draw background badge / box
    if (backgroundStyle != TextBackgroundStyle.none) {
      final Color effectiveBgColor = backgroundColor.withValues(
        alpha: (backgroundOpacity * opacity).clamp(0.0, 1.0),
      );

      switch (backgroundStyle) {
        case TextBackgroundStyle.filledBox:
          final Paint bgPaint = Paint()
            ..color = effectiveBgColor
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(bgRect, Radius.circular(borderRadius)),
            bgPaint,
          );
          break;

        case TextBackgroundStyle.roundedPill:
          final Paint pillPaint = Paint()
            ..color = effectiveBgColor
            ..style = PaintingStyle.fill;
          final double pillRadius = bgRect.height / 2.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(bgRect, Radius.circular(pillRadius)),
            pillPaint,
          );
          break;

        case TextBackgroundStyle.outlineBox:
          final Paint outlinePaint = Paint()
            ..color = effectiveBgColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(bgRect, Radius.circular(borderRadius)),
            outlinePaint,
          );
          break;

        case TextBackgroundStyle.none:
          break;
      }
    }

    final Offset textOffset = Offset(
      (boxSize.width - textW) / 2,
      (boxSize.height - textH) / 2,
    );

    // 2. Stroke Outline
    if (hasStroke && strokeWidth > 0) {
      final TextPainter strokePainter = TextPainter(
        text: TextSpan(
          text: displayText,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth * 2.0
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor.withValues(alpha: opacity.clamp(0.0, 1.0)),
          ),
        ),
        textAlign: textAlign,
        textDirection: TextDirection.ltr,
      );
      strokePainter.layout();
      strokePainter.paint(canvas, textOffset);
    }

    // 3. Main Text
    final List<Shadow> shadows = [];
    if (hasShadow && shadowBlurRadius > 0) {
      shadows.add(
        Shadow(
          color: shadowColor.withValues(
            alpha: (shadowColor.a * opacity).clamp(0.0, 1.0),
          ),
          blurRadius: shadowBlurRadius,
          offset: shadowOffset,
        ),
      );
    }

    final TextPainter fillPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: baseStyle.copyWith(
          color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
          shadows: shadows,
        ),
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    fillPainter.layout();
    fillPainter.paint(canvas, textOffset);
  }
}
