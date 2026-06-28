import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/recipe.dart';

/// A large, immersive recipe card used in the "Trending" carousel.
class FeaturedRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onSaveTap;

  const FeaturedRecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.isSaved = false,
    this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: SizedBox(
          width: 280,
          height: 340,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetworkImage(url: recipe.imageUrl),
              const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.imageScrim)),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: _Badge(
                  icon: Icons.local_fire_department_rounded,
                  label: '${recipe.calories} kcal',
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _SaveButton(isSaved: isSaved, onTap: onSaveTap),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Pill(label: recipe.cuisine),
                        AppSpacing.hGapSm,
                        const Icon(Icons.star_rounded, color: AppColors.rating, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          recipe.rating.toStringAsFixed(1),
                          style: text.labelMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    AppSpacing.vGapSm,
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: Colors.white70, size: 15),
                        const SizedBox(width: 4),
                        Text('${recipe.totalMinutes} min',
                            style: text.bodySmall?.copyWith(color: Colors.white70)),
                        const SizedBox(width: 12),
                        const Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 15),
                        const SizedBox(width: 4),
                        Text(recipe.difficulty,
                            style: text.bodySmall?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact horizontal card for vertical lists (recommendations, search results).
class RecipeListCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onSaveTap;
  final String? heroTag;

  const RecipeListCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.isSaved = false,
    this.onSaveTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget image = ClipRRect(
      borderRadius: AppRadius.brMd,
      child: SizedBox(width: 96, height: 96, child: _NetworkImage(url: recipe.imageUrl)),
    );
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    return Material(
      color: scheme.surface,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brLg,
            boxShadow: AppColors.cardShadow,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              image,
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(recipe.cuisine.toUpperCase(),
                        style: text.labelSmall?.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(recipe.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.rating, size: 15),
                        const SizedBox(width: 3),
                        Text(recipe.rating.toStringAsFixed(1), style: text.bodySmall),
                        const SizedBox(width: 10),
                        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text('${recipe.totalMinutes}m', style: text.bodySmall),
                        const SizedBox(width: 10),
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text('${recipe.calories}', style: text.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSaveTap,
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? AppColors.coral : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  final String url;
  const _NetworkImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => Shimmer.fromColors(
        baseColor: AppColors.surfaceAlt,
        highlightColor: AppColors.surface,
        child: Container(color: AppColors.surfaceAlt),
      ),
      errorWidget: (_, _, _) => Container(
        color: AppColors.surfaceAlt,
        child: const Icon(Icons.restaurant_rounded, color: AppColors.textTertiary),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.brSm,
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback? onTap;
  const _SaveButton({required this.isSaved, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isSaved ? AppColors.coral : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
