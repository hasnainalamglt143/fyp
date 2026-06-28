import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Displays a star rating. When [onChanged] is provided the stars become
/// tappable for input (used in the write-review sheet).
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.round();
        final star = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: AppColors.rating,
          size: size,
        );
        if (onChanged == null) return star;
        return GestureDetector(
          onTap: () => onChanged!(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: star,
          ),
        );
      }),
    );
  }
}
