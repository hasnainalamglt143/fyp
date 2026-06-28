import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';

/// A cached network image with shimmer placeholder and graceful error state,
/// optionally wrapped in a [Hero] for shared-element transitions into the
/// recipe detail screen.
class RecipeHeroImage extends StatelessWidget {
  final String url;
  final String? heroTag;
  final BoxFit fit;
  final bool scrim;

  const RecipeHeroImage({
    super.key,
    required this.url,
    this.heroTag,
    this.fit = BoxFit.cover,
    this.scrim = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, _) => Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      ),
      errorWidget: (_, _, _) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.restaurant_rounded, color: AppColors.textTertiary, size: 32),
      ),
    );

    if (scrim) {
      image = Stack(
        fit: StackFit.expand,
        children: [
          image,
          const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.imageScrim)),
        ],
      );
    }

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: image);
    }
    return image;
  }
}
