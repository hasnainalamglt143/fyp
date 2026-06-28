import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

const _waterBlue = Color(0xFF3AA0FF);
const _goalGlasses = 8;

class HydrationNotifier extends Notifier<int> {
  @override
  int build() => 3;

  void add() {
    if (state < 20) state = state + 1;
  }

  void remove() {
    if (state > 0) state = state - 1;
  }
}

final hydrationProvider = NotifierProvider<HydrationNotifier, int>(HydrationNotifier.new);

class HydrationScreen extends ConsumerWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final glasses = ref.watch(hydrationProvider);
    final progress = (glasses / _goalGlasses).clamp(0.0, 1.0);
    final ml = glasses * 250;

    return Scaffold(
      appBar: AppBar(title: const Text('Hydration')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Progress ring
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 16,
                        strokeCap: StrokeCap.round,
                        backgroundColor: _waterBlue.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation(_waterBlue),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop_rounded, color: _waterBlue, size: 36),
                      AppSpacing.vGapSm,
                      Text('$glasses / $_goalGlasses',
                          style: text.displaySmall),
                      Text('glasses · ${ml}ml', style: text.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.vGapXl,
          // Add / remove
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(hydrationProvider.notifier).remove(),
                  icon: const Icon(Icons.remove_rounded),
                  label: const Text('Remove'),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => ref.read(hydrationProvider.notifier).add(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _waterBlue,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add a glass'),
                ),
              ),
            ],
          ),
          AppSpacing.vGapXl,
          // Today's glasses visual
          Text("TODAY'S INTAKE",
              style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: List.generate(_goalGlasses, (i) {
              final filled = i < glasses;
              return Icon(
                filled ? Icons.local_drink_rounded : Icons.local_drink_outlined,
                color: filled ? _waterBlue : AppColors.textTertiary,
                size: 34,
              );
            }),
          ),
          AppSpacing.vGapXl,
          // Reminder settings
          Text('REMINDERS',
              style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.vGapSm,
          _settingTile(context, Icons.notifications_active_rounded, 'Reminders', 'Every 2 hours', trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: _waterBlue)),
          _settingTile(context, Icons.bedtime_rounded, 'Quiet hours', '10:00 PM – 7:00 AM'),
          _settingTile(context, Icons.flag_rounded, 'Daily goal', '$_goalGlasses glasses (2 L)'),
        ],
      ),
    );
  }

  Widget _settingTile(BuildContext context, IconData icon, String title, String subtitle,
      {Widget? trailing}) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _waterBlue.withValues(alpha: 0.12),
                borderRadius: AppRadius.brSm,
              ),
              child: const Icon(Icons.water_drop_rounded, color: _waterBlue, size: 20),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  Text(subtitle, style: text.bodySmall),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
