import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A prominent gradient call-to-action button used across the app for primary
/// actions (Start cooking, Generate, Save plan, …).
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient = AppColors.brandGradient,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final child = Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.brMd,
        boxShadow: enabled ? AppColors.cardShadow : null,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: enabled ? Colors.white : AppColors.textTertiary, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: enabled ? Colors.white : AppColors.textTertiary,
                  fontSize: 16,
                ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onPressed,
        child: child,
      ),
    );
  }
}
