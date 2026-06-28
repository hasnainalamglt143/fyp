import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_spacing.dart';

/// Shimmer skeleton placeholders shown while content "loads" (useful when the
/// real API is wired in later).
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.brSm,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
      ),
    );
  }
}

/// A skeleton row matching the recipe list card layout.
class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SkeletonBox(width: 96, height: 96, radius: AppRadius.brMd),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SkeletonBox(width: 80, height: 10),
              SizedBox(height: 10),
              SkeletonBox(height: 16),
              SizedBox(height: 10),
              SkeletonBox(width: 140, height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
