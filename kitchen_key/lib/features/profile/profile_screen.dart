import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../saved/saved_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final savedCount = ref.watch(savedRecipesProvider).length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: AppRadius.brLg,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 38),
                  ),
                  AppSpacing.hGapLg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mark Khan',
                            style: text.titleLarge?.copyWith(color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('markikhan104@gmail.com',
                            style: text.bodySmall?.copyWith(color: Colors.white70)),
                        AppSpacing.vGapSm,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: AppRadius.brSm,
                          ),
                          child: Text('🍳 Intermediate Cook',
                              style: text.labelSmall?.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            AppSpacing.vGapLg,
            // Stats row
            Row(
              children: [
                _StatCard(value: '$savedCount', label: 'Saved', icon: Icons.bookmark_rounded),
                AppSpacing.hGapMd,
                const _StatCard(value: '12', label: 'Cooked', icon: Icons.restaurant_rounded),
                AppSpacing.hGapMd,
                const _StatCard(value: '4.8', label: 'Avg rating', icon: Icons.star_rounded),
              ],
            ),
            AppSpacing.vGapXl,
            _section(text, 'Preferences'),
            _Tile(icon: Icons.restaurant_menu_rounded, title: 'Dietary preferences', subtitle: 'Vegetarian, High-Protein', onTap: () => context.push('/profile/edit')),
            _Tile(icon: Icons.no_food_rounded, title: 'Allergies', subtitle: 'Peanuts', onTap: () => context.push('/profile/edit')),
            _Tile(icon: Icons.bar_chart_rounded, title: 'Cooking skill level', subtitle: 'Intermediate', onTap: () => context.push('/profile/edit')),
            AppSpacing.vGapLg,
            _section(text, 'Health & Wellness'),
            _Tile(icon: Icons.water_drop_rounded, title: 'Hydration tracker', subtitle: 'On · every 2 hours', iconColor: const Color(0xFF3AA0FF), onTap: () => context.push('/hydration')),
            _Tile(icon: Icons.monitor_heart_rounded, title: 'Nutrition tracking', subtitle: 'Daily goal 2000 kcal', onTap: () => context.push('/nutrition')),
            AppSpacing.vGapLg,
            _section(text, 'App'),
            _Tile(icon: Icons.notifications_rounded, title: 'Notifications', onTap: () => context.push('/settings')),
            _Tile(icon: Icons.dark_mode_rounded, title: 'Appearance', subtitle: 'Theme & display', onTap: () => context.push('/settings')),
            _Tile(icon: Icons.settings_rounded, title: 'Settings', onTap: () => context.push('/settings')),
            const _Tile(icon: Icons.lock_rounded, title: 'Privacy & Security'),
            const _Tile(icon: Icons.help_outline_rounded, title: 'Help & Support'),
            AppSpacing.vGapLg,
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Log out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
            ),
            AppSpacing.vGapMd,
            Center(
              child: Text('Kitchen Key v1.0.0',
                  style: text.bodySmall?.copyWith(color: AppColors.textTertiary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(TextTheme text, String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(title, style: text.titleMedium),
      );

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access your recipes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, minimumSize: const Size(100, 44)),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/login');
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            AppSpacing.vGapSm,
            Text(value, style: text.titleLarge),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.title, this.subtitle, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall),
                      if (subtitle != null)
                        Text(subtitle!, style: text.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
