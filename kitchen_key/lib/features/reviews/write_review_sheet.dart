import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/rating_stars.dart';

/// Bottom sheet to compose a review: star rating, text and an (mock) photo add.
class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({super.key});

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  int _rating = 0;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: AppRadius.brPill),
            ),
          ),
          AppSpacing.vGapLg,
          Text('Rate this recipe', style: text.titleLarge),
          const SizedBox(height: 6),
          Text('Share your experience with other cooks', style: text.bodyMedium),
          AppSpacing.vGapLg,
          Center(
            child: RatingStars(
              rating: _rating.toDouble(),
              size: 40,
              onChanged: (v) => setState(() => _rating = v),
            ),
          ),
          AppSpacing.vGapLg,
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell us what you thought…',
              alignLabelWithHint: true,
            ),
          ),
          AppSpacing.vGapMd,
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add a photo'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
          AppSpacing.vGapLg,
          ElevatedButton(
            onPressed: _rating == 0
                ? null
                : () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanks for your review! 🌟')),
                    );
                  },
            child: const Text('Submit review'),
          ),
        ],
      ),
    );
  }
}
