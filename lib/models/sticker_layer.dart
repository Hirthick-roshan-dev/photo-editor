import 'package:flutter/material.dart';

/// Type of sticker content
enum StickerType {
  emoji,
  iconBadge;

  String get label {
    switch (this) {
      case StickerType.emoji:
        return 'Emoji';
      case StickerType.iconBadge:
        return 'Badge';
    }
  }
}

/// Category metadata for sticker catalog
class StickerCategory {
  final String id;
  final String label;
  final IconData icon;

  const StickerCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  static const List<StickerCategory> categories = [
    StickerCategory(
      id: 'popular',
      label: 'Popular',
      icon: Icons.local_fire_department_rounded,
    ),
    StickerCategory(
      id: 'faces',
      label: 'Faces',
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
    StickerCategory(
      id: 'animals',
      label: 'Animals',
      icon: Icons.pets_rounded,
    ),
    StickerCategory(
      id: 'food',
      label: 'Food',
      icon: Icons.fastfood_rounded,
    ),
    StickerCategory(
      id: 'vibes',
      label: 'Vibes',
      icon: Icons.auto_awesome_rounded,
    ),
    StickerCategory(
      id: 'objects',
      label: 'Objects',
      icon: Icons.category_rounded,
    ),
    StickerCategory(
      id: 'badges',
      label: 'Badges',
      icon: Icons.verified_rounded,
    ),
  ];
}

/// Catalog item representing a sticker in the picker
class StickerCatalogItem {
  final String id;
  final String content;
  final String categoryId;
  final StickerType type;
  final IconData? icon;

  const StickerCatalogItem({
    required this.id,
    required this.content,
    required this.categoryId,
    this.type = StickerType.emoji,
    this.icon,
  });

  static const List<StickerCatalogItem> catalog = [
    // --- POPULAR ---
    StickerCatalogItem(id: 'pop_fire', content: '🔥', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_sparkles', content: '✨', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_heart', content: '💖', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_rocket', content: '🚀', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_100', content: '💯', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_cool', content: '😎', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_party', content: '🎉', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_star', content: '🌟', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_crown', content: '👑', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_celebrate', content: '🥳', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_zap', content: '⚡', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_gem', content: '💎', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_pizza', content: '🍕', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_dog', content: '🐶', categoryId: 'popular'),
    StickerCatalogItem(id: 'pop_rainbow', content: '🌈', categoryId: 'popular'),

    // --- EXPRESSIONS / FACES ---
    StickerCatalogItem(id: 'face_joy', content: '😂', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_star_struck', content: '🤩', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_heart_eyes', content: '😍', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_pleading', content: '🥺', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_wink_tongue', content: '😜', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_halo', content: '😇', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_cowboy', content: '🤠', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_monocle', content: '🧐', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_shush', content: '🤫', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_exploding', content: '🤯', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_drool', content: '🤤', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_cold', content: '🥶', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_hot', content: '🥵', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_devil', content: '😈', categoryId: 'faces'),
    StickerCatalogItem(id: 'face_robot', content: '🤖', categoryId: 'faces'),

    // --- ANIMALS & NATURE ---
    StickerCatalogItem(id: 'anim_dog', content: '🐶', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_cat', content: '🐱', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_panda', content: '🐼', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_fox', content: '🦊', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_unicorn', content: '🦄', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_rabbit', content: '🐰', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_koala', content: '🐨', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_lion', content: '🦁', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_tiger', content: '🐯', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_chick', content: '🐥', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_butterfly', content: '🦋', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_octopus', content: '🐙', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_flower', content: '🌸', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_sunflower', content: '🌻', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_clover', content: '🍀', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_palm', content: '🌴', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_mushroom', content: '🍄', categoryId: 'animals'),
    StickerCatalogItem(id: 'anim_wave', content: '🌊', categoryId: 'animals'),

    // --- FOOD & DRINKS ---
    StickerCatalogItem(id: 'food_pizza', content: '🍕', categoryId: 'food'),
    StickerCatalogItem(id: 'food_burger', content: '🍔', categoryId: 'food'),
    StickerCatalogItem(id: 'food_fries', content: '🍟', categoryId: 'food'),
    StickerCatalogItem(id: 'food_taco', content: '🌮', categoryId: 'food'),
    StickerCatalogItem(id: 'food_icecream', content: '🍦', categoryId: 'food'),
    StickerCatalogItem(id: 'food_donut', content: '🍩', categoryId: 'food'),
    StickerCatalogItem(id: 'food_coffee', content: '☕', categoryId: 'food'),
    StickerCatalogItem(id: 'food_cocktail', content: '🍹', categoryId: 'food'),
    StickerCatalogItem(id: 'food_strawberry', content: '🍓', categoryId: 'food'),
    StickerCatalogItem(id: 'food_avocado', content: '🥑', categoryId: 'food'),
    StickerCatalogItem(id: 'food_sushi', content: '🍣', categoryId: 'food'),
    StickerCatalogItem(id: 'food_popcorn', content: '🍿', categoryId: 'food'),
    StickerCatalogItem(id: 'food_cupcake', content: '🧁', categoryId: 'food'),
    StickerCatalogItem(id: 'food_cookie', content: '🍪', categoryId: 'food'),
    StickerCatalogItem(id: 'food_cake', content: '🎂', categoryId: 'food'),
    StickerCatalogItem(id: 'food_watermelon', content: '🍉', categoryId: 'food'),

    // --- VIBES & MAGIC ---
    StickerCatalogItem(id: 'vibe_rainbow', content: '🌈', categoryId: 'vibes'),
    StickerCatalogItem(id: 'vibe_sun', content: '☀️', categoryId: 'vibes'),
    StickerCatalogItem(id: 'vibe_moon', content: '🌙', categoryId: 'vibes'),
    StickerCatalogItem(id: 'vibe_lightning', content: '⚡', categoryId: 'vibes'),
    StickerCatalogItem(id: 'vibe_crystal', content: '🔮', categoryId: 'vibes'),
    StickerCatalogItem(id: 'vibe_dizzy', content: '💫', categoryId: 'vibes'),
    StickerCatalogItem(id: 'vibe_diamond', content: '💎', categoryId: 'vibes'),
    StickerCatalogItem(id: 'vibe_dove', content: '🕊️', categoryId: 'vibes'),
    StickerCatalogItem(id: 'vibe_balloon', content: '🎈', categoryId: 'vibes'),
    StickerCatalogItem(id: 'vibe_gift', content: '🎁', categoryId: 'vibes'),
    StickerCatalogItem(id: 'vibe_ribbon', content: '🎀', categoryId: 'vibes'),

    // --- OBJECTS & LIFESTYLE ---
    StickerCatalogItem(id: 'obj_sunglasses', content: '🕶️', categoryId: 'objects'),
    StickerCatalogItem(id: 'obj_hat', content: '👒', categoryId: 'objects'),
    StickerCatalogItem(id: 'obj_guitar', content: '🎸', categoryId: 'objects'),
    StickerCatalogItem(id: 'obj_camera', content: '📸', categoryId: 'objects'),
    StickerCatalogItem(id: 'obj_palette', content: '🎨', categoryId: 'objects'),
    StickerCatalogItem(id: 'obj_trophy', content: '🏆', categoryId: 'objects'),
    StickerCatalogItem(id: 'obj_medal', content: '🎖️', categoryId: 'objects'),
    StickerCatalogItem(id: 'obj_lightbulb', content: '💡', categoryId: 'objects'),
    StickerCatalogItem(id: 'obj_tag', content: '🏷️', categoryId: 'objects'),

    // --- BADGES & SEALS ---
    StickerCatalogItem(
      id: 'badge_verified',
      content: 'badge_verified',
      categoryId: 'badges',
      type: StickerType.iconBadge,
      icon: Icons.verified_rounded,
    ),
    StickerCatalogItem(
      id: 'badge_favorite',
      content: 'badge_favorite',
      categoryId: 'badges',
      type: StickerType.iconBadge,
      icon: Icons.favorite_rounded,
    ),
    StickerCatalogItem(
      id: 'badge_star',
      content: 'badge_star',
      categoryId: 'badges',
      type: StickerType.iconBadge,
      icon: Icons.star_rounded,
    ),
    StickerCatalogItem(
      id: 'badge_award',
      content: 'badge_award',
      categoryId: 'badges',
      type: StickerType.iconBadge,
      icon: Icons.workspace_premium_rounded,
    ),
    StickerCatalogItem(
      id: 'badge_flame',
      content: 'badge_flame',
      categoryId: 'badges',
      type: StickerType.iconBadge,
      icon: Icons.whatshot_rounded,
    ),
    StickerCatalogItem(
      id: 'badge_sparkle',
      content: 'badge_sparkle',
      categoryId: 'badges',
      type: StickerType.iconBadge,
      icon: Icons.auto_awesome_rounded,
    ),
    StickerCatalogItem(
      id: 'badge_shield',
      content: 'badge_shield',
      categoryId: 'badges',
      type: StickerType.iconBadge,
      icon: Icons.shield_rounded,
    ),
    StickerCatalogItem(
      id: 'badge_thumb_up',
      content: 'badge_thumb_up',
      categoryId: 'badges',
      type: StickerType.iconBadge,
      icon: Icons.thumb_up_rounded,
    ),
    StickerCatalogItem(
      id: 'badge_camera',
      content: 'badge_camera',
      categoryId: 'badges',
      type: StickerType.iconBadge,
      icon: Icons.camera_alt_rounded,
    ),
  ];
}

/// Represents a single sticker placed on the canvas
class StickerLayer {
  final String id;
  final StickerType type;
  final String content; // Emoji string or icon name
  final IconData? icon; // If type is iconBadge
  final Offset position; // Canvas center point
  final double size; // Base size (pt)
  final double scale; // Scale factor (0.2 to 5.0)
  final double rotation; // Radians
  final bool isFlippedH; // Horizontal flip
  final bool isFlippedV; // Vertical flip
  final double opacity; // 0.1 to 1.0
  final Color? tintColor; // Optional tint for icon badges
  final bool hasShadow;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final Size canvasSize;

  const StickerLayer({
    required this.id,
    this.type = StickerType.emoji,
    required this.content,
    this.icon,
    required this.position,
    this.size = 64.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isFlippedH = false,
    this.isFlippedV = false,
    this.opacity = 1.0,
    this.tintColor = const Color(0xFF2563EB),
    this.hasShadow = true,
    this.shadowColor = const Color(0x66000000),
    this.shadowBlurRadius = 4.0,
    this.shadowOffset = const Offset(1.5, 1.5),
    required this.canvasSize,
  });

  StickerLayer copyWith({
    String? id,
    StickerType? type,
    String? content,
    IconData? icon,
    Offset? position,
    double? size,
    double? scale,
    double? rotation,
    bool? isFlippedH,
    bool? isFlippedV,
    double? opacity,
    Color? tintColor,
    bool? hasShadow,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    Size? canvasSize,
  }) {
    return StickerLayer(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      icon: icon ?? this.icon,
      position: position ?? this.position,
      size: size ?? this.size,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      isFlippedH: isFlippedH ?? this.isFlippedH,
      isFlippedV: isFlippedV ?? this.isFlippedV,
      opacity: opacity ?? this.opacity,
      tintColor: tintColor ?? this.tintColor,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      canvasSize: canvasSize ?? this.canvasSize,
    );
  }

  /// Measures the layout size of this sticker layer.
  Size measureSize({double avgScale = 1.0}) {
    final double effectiveSize = (size * scale * avgScale).clamp(8.0, 1000.0);
    return Size(effectiveSize, effectiveSize);
  }

  /// Renders this sticker in a local widget box.
  void renderLocalBox(Canvas canvas, Size boxSize) {
    final double effectiveSize = (size * scale).clamp(8.0, 1000.0);
    final double halfW = boxSize.width / 2.0;
    final double halfH = boxSize.height / 2.0;

    canvas.save();
    canvas.translate(halfW, halfH);

    // Apply flip transforms
    canvas.scale(isFlippedH ? -1.0 : 1.0, isFlippedV ? -1.0 : 1.0);

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

    if (type == StickerType.emoji) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: content,
          style: TextStyle(
            fontSize: effectiveSize,
            shadows: shadows,
            color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    } else if (icon != null) {
      final Color color = (tintColor ?? const Color(0xFF2563EB)).withValues(
        alpha: opacity.clamp(0.0, 1.0),
      );
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon!.codePoint),
          style: TextStyle(
            inherit: false,
            color: color,
            fontSize: effectiveSize,
            fontFamily: icon!.fontFamily,
            package: icon!.fontPackage,
            shadows: shadows,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    }

    canvas.restore();
  }

  /// Renders this sticker onto a full-resolution [Canvas] matching [targetSize].
  void renderToCanvas(Canvas canvas, Size targetSize) {
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
    final double effectiveSize = (size * scale * avgScale).clamp(4.0, 2000.0);

    canvas.save();
    canvas.translate(scaledCenter.dx, scaledCenter.dy);
    canvas.rotate(rotation);
    canvas.scale(isFlippedH ? -1.0 : 1.0, isFlippedV ? -1.0 : 1.0);

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

    if (type == StickerType.emoji) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: content,
          style: TextStyle(
            fontSize: effectiveSize,
            shadows: shadows,
            color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    } else if (icon != null) {
      final Color color = (tintColor ?? const Color(0xFF2563EB)).withValues(
        alpha: opacity.clamp(0.0, 1.0),
      );
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon!.codePoint),
          style: TextStyle(
            inherit: false,
            color: color,
            fontSize: effectiveSize,
            fontFamily: icon!.fontFamily,
            package: icon!.fontPackage,
            shadows: shadows,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    }

    canvas.restore();
  }
}
