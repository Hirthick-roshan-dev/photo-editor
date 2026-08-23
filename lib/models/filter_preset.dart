import 'package:flutter/material.dart';

enum FilterCategory {
  all('All'),
  color('Color'),
  vintage('Vintage'),
  monochrome('B&W'),
  cinematic('Cinematic'),
  artistic('Art');

  final String label;
  const FilterCategory(this.label);
}

class FilterPreset {
  final String id;
  final String name;
  final FilterCategory category;
  final IconData? icon;
  final List<double> matrix;

  const FilterPreset({
    required this.id,
    required this.name,
    required this.category,
    this.icon,
    required this.matrix,
  });

  /// Identity 4x5 color matrix for baseline comparison
  static const List<double> identityMatrix = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  /// Interpolates the filter matrix based on intensity (0.0 to 1.0)
  List<double> getAdjustedMatrix(double intensity) {
    final double t = intensity.clamp(0.0, 1.0);
    if (t == 1.0) return matrix;
    if (t == 0.0) return identityMatrix;

    final List<double> result = List<double>.filled(20, 0.0);
    for (int i = 0; i < 20; i++) {
      result[i] = identityMatrix[i] * (1.0 - t) + matrix[i] * t;
    }
    return result;
  }

  static const List<FilterPreset> presets = [
    FilterPreset(
      id: 'original',
      name: 'Original',
      category: FilterCategory.all,
      icon: Icons.image_outlined,
      matrix: identityMatrix,
    ),
    FilterPreset(
      id: 'vivid',
      name: 'Vivid',
      category: FilterCategory.color,
      icon: Icons.wb_sunny_rounded,
      matrix: [
        1.25, 0.0, 0.0, 0.0, -10.0,
        0.0, 1.25, 0.0, 0.0, -10.0,
        0.0, 0.0, 1.25, 0.0, -10.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'warm',
      name: 'Warm',
      category: FilterCategory.color,
      icon: Icons.local_fire_department_rounded,
      matrix: [
        1.15, 0.0, 0.0, 0.0, 18.0,
        0.0, 1.05, 0.0, 0.0, 6.0,
        0.0, 0.0, 0.85, 0.0, -16.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'cool',
      name: 'Cool',
      category: FilterCategory.color,
      icon: Icons.ac_unit_rounded,
      matrix: [
        0.88, 0.0, 0.0, 0.0, -12.0,
        0.0, 0.98, 0.0, 0.0, 2.0,
        0.0, 0.0, 1.22, 0.0, 22.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'cinematic',
      name: 'Teal & Orange',
      category: FilterCategory.cinematic,
      icon: Icons.movie_filter_rounded,
      matrix: [
        1.25, 0.0, -0.1, 0.0, 12.0,
        0.0, 1.0, 0.1, 0.0, 0.0,
        -0.1, 0.1, 1.35, 0.0, -12.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'vintage',
      name: 'Vintage',
      category: FilterCategory.vintage,
      icon: Icons.camera_roll_rounded,
      matrix: [
        0.9, 0.1, 0.1, 0.0, 28.0,
        0.0, 0.8, 0.1, 0.0, 18.0,
        0.1, 0.1, 0.6, 0.0, 32.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'sepia',
      name: 'Sepia',
      category: FilterCategory.vintage,
      icon: Icons.filter_vintage_rounded,
      matrix: [
        0.393, 0.769, 0.189, 0.0, 0.0,
        0.349, 0.686, 0.168, 0.0, 0.0,
        0.272, 0.534, 0.131, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'matte',
      name: 'Matte Fade',
      category: FilterCategory.vintage,
      icon: Icons.blur_on_rounded,
      matrix: [
        0.88, 0.0, 0.0, 0.0, 32.0,
        0.0, 0.88, 0.0, 0.0, 32.0,
        0.0, 0.0, 0.88, 0.0, 32.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'mono',
      name: 'B&W Classic',
      category: FilterCategory.monochrome,
      icon: Icons.contrast_rounded,
      matrix: [
        0.2126, 0.7152, 0.0722, 0.0, 0.0,
        0.2126, 0.7152, 0.0722, 0.0, 0.0,
        0.2126, 0.7152, 0.0722, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'noir',
      name: 'Noir Dramatic',
      category: FilterCategory.monochrome,
      icon: Icons.nightlight_round,
      matrix: [
        0.38, 0.88, 0.18, 0.0, -48.0,
        0.38, 0.88, 0.18, 0.0, -48.0,
        0.38, 0.88, 0.18, 0.0, -48.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'silver',
      name: 'Cold Chrome',
      category: FilterCategory.monochrome,
      icon: Icons.tune_rounded,
      matrix: [
        0.65, 0.55, 0.2, 0.0, -12.0,
        0.35, 0.7, 0.2, 0.0, -12.0,
        0.3, 0.35, 0.85, 0.0, 15.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'dramatic',
      name: 'Dramatic',
      category: FilterCategory.cinematic,
      icon: Icons.flash_on_rounded,
      matrix: [
        1.38, 0.0, 0.0, 0.0, -28.0,
        0.0, 1.38, 0.0, 0.0, -28.0,
        0.0, 0.0, 1.38, 0.0, -28.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'emerald',
      name: 'Emerald',
      category: FilterCategory.artistic,
      icon: Icons.park_rounded,
      matrix: [
        0.82, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.28, 0.1, 0.0, 18.0,
        0.0, 0.0, 0.92, 0.0, 6.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'cyberpunk',
      name: 'Cyberpunk',
      category: FilterCategory.artistic,
      icon: Icons.electric_bolt_rounded,
      matrix: [
        1.45, -0.2, 0.2, 0.0, 18.0,
        -0.1, 1.15, 0.2, 0.0, -12.0,
        0.2, 0.1, 1.55, 0.0, 30.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'pastel',
      name: 'Pastel Glow',
      category: FilterCategory.artistic,
      icon: Icons.palette_outlined,
      matrix: [
        1.12, 0.05, 0.05, 0.0, 22.0,
        0.05, 1.06, 0.05, 0.0, 16.0,
        0.05, 0.05, 1.18, 0.0, 28.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
    FilterPreset(
      id: 'solar',
      name: 'Solar Gold',
      category: FilterCategory.color,
      icon: Icons.wb_twilight_rounded,
      matrix: [
        1.28, 0.05, 0.0, 0.0, 22.0,
        0.0, 1.16, 0.0, 0.0, 16.0,
        0.0, 0.0, 0.72, 0.0, -22.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
    ),
  ];
}
