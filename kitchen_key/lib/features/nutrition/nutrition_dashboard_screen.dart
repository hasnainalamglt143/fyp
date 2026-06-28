import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock_data.dart';

class NutritionDashboardScreen extends StatelessWidget {
  const NutritionDashboardScreen({super.key});

  static const _calorieGoal = 2000;
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final log = MockData.nutritionLog;
    final consumed = log.fold<int>(0, (s, e) => s + e.calories);
    final protein = log.fold<int>(0, (s, e) => s + e.proteinG);
    final carbs = log.fold<int>(0, (s, e) => s + e.carbsG);
    final fat = log.fold<int>(0, (s, e) => s + e.fatG);
    final progress = (consumed / _calorieGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Calorie ring card
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.brLg,
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.primarySurface,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$consumed', style: text.headlineSmall),
                          Text('kcal', style: text.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily goal', style: text.bodySmall),
                      Text('$_calorieGoal kcal', style: text.titleLarge),
                      AppSpacing.vGapSm,
                      Text('${_calorieGoal - consumed} kcal remaining',
                          style: text.bodyMedium?.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapLg,
          // Macros
          Row(
            children: [
              _macroCard(context, 'Protein', protein, const Color(0xFF3AA0FF)),
              AppSpacing.hGapMd,
              _macroCard(context, 'Carbs', carbs, AppColors.accent),
              AppSpacing.hGapMd,
              _macroCard(context, 'Fat', fat, AppColors.coral),
            ],
          ),
          AppSpacing.vGapXl,
          // Weekly chart
          Text('THIS WEEK', style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.vGapMd,
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.brLg,
              boxShadow: AppColors.cardShadow,
            ),
            child: BarChart(
              BarChartData(
                maxY: 2600,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_days[value.toInt() % 7], style: text.bodySmall),
                      ),
                    ),
                  ),
                ),
                barGroups: MockData.weeklyCalories.asMap().entries.map((e) {
                  final isToday = e.key == 6;
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value,
                      width: 18,
                      borderRadius: AppRadius.brSm,
                      color: isToday ? AppColors.primary : AppColors.primarySurface,
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
          AppSpacing.vGapXl,
          // Logged meals
          Text("TODAY'S MEALS", style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.vGapMd,
          ...log.map((e) => Padding(
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
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accentSurface,
                          borderRadius: AppRadius.brSm,
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: AppColors.accentDark, size: 20),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, style: text.titleSmall),
                            Text(e.meal, style: text.bodySmall),
                          ],
                        ),
                      ),
                      Text('${e.calories} kcal', style: text.titleSmall),
                    ],
                  ),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log meal'),
      ),
    );
  }

  Widget _macroCard(BuildContext context, String label, int grams, Color color) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: AppRadius.brMd,
        ),
        child: Column(
          children: [
            Text('${grams}g', style: text.titleLarge?.copyWith(color: color)),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
