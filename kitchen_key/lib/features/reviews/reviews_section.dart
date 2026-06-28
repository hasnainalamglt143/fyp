import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/review.dart';
import '../../shared/widgets/rating_stars.dart';
import 'write_review_sheet.dart';

/// Ratings summary + review list, embedded in the recipe detail screen.
class ReviewsSection extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final List<Review> reviews;

  const ReviewsSection({
    super.key,
    required this.rating,
    required this.reviewCount,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews', style: text.titleLarge),
            TextButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const WriteReviewSheet(),
              ),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Write'),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        // Summary
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.brLg,
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(rating.toStringAsFixed(1), style: text.displaySmall),
                  RatingStars(rating: rating, size: 16),
                  const SizedBox(height: 4),
                  Text('$reviewCount reviews', style: text.bodySmall),
                ],
              ),
              AppSpacing.hGapLg,
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final fraction = [0.7, 0.2, 0.06, 0.03, 0.01][i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star', style: text.bodySmall),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppRadius.brPill,
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 6,
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                valueColor: const AlwaysStoppedAnimation(AppColors.rating),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGapLg,
        ...reviews.map((r) => _ReviewTile(review: r)),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySurface,
                child: Text(review.avatarColorSeed,
                    style: text.titleSmall?.copyWith(color: AppColors.primary)),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.author, style: text.titleSmall),
                    Text(review.timeAgo, style: text.bodySmall),
                  ],
                ),
              ),
              RatingStars(rating: review.rating, size: 14),
            ],
          ),
          AppSpacing.vGapSm,
          Text(review.text, style: text.bodyMedium),
          if (review.photoUrl != null) ...[
            AppSpacing.vGapSm,
            ClipRRect(
              borderRadius: AppRadius.brMd,
              child: Image.network(review.photoUrl!,
                  height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          AppSpacing.vGapSm,
          Row(
            children: [
              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('Helpful (${review.helpful})', style: text.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
