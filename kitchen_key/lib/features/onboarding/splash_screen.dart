import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Branded splash shown on launch before routing into onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.brXl,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(Icons.restaurant_menu_rounded,
                  color: AppColors.primary, size: 56),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
            AppSpacing.vGapXl,
            Text(
              'Kitchen Key',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.4, end: 0),
            const SizedBox(height: 6),
            Text(
              'Unlock your next favourite meal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
