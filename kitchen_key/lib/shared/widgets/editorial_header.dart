import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// An editorial section header: a small uppercase eyebrow label above a large
/// serif title, with an optional trailing action.
class EditorialHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? eyebrowColor;

  const EditorialHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.eyebrowColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(),
                  style: AppTypography.eyebrow(context,
                      color: eyebrowColor ?? AppColors.accent)),
              const SizedBox(height: 6),
              Text(title, style: text.headlineSmall),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              children: [
                Text(actionLabel!,
                    style: text.labelMedium?.copyWith(color: AppColors.primary)),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}
