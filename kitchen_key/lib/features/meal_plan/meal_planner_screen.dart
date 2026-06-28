import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock_data.dart';
import '../../data/models/recipe.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  int _selectedDay = 2; // Wed
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dates = [12, 13, 14, 15, 16, 17, 18];

  // Mock assigned meals per slot.
  final Map<String, Recipe?> _plan = {
    'Breakfast': MockData.recipes[2],
    'Lunch': MockData.recipes[1],
    'Dinner': MockData.recipes[0],
  };

  int get _dayCalories =>
      _plan.values.whereType<Recipe>().fold(0, (sum, r) => sum + r.calories);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meal Planner', style: text.headlineMedium),
                        Text('This week · June', style: text.bodyMedium),
                      ],
                    ),
                    Material(
                      color: AppColors.primarySurface,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                        tooltip: 'Auto-generate plan',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: _days.length,
                  separatorBuilder: (_, _) => AppSpacing.hGapSm,
                  itemBuilder: (context, i) {
                    final selected = i == _selectedDay;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.brandGradient : null,
                          color: selected ? null : Theme.of(context).colorScheme.surface,
                          borderRadius: AppRadius.brMd,
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_days[i],
                                style: text.labelSmall?.copyWith(
                                    color: selected ? Colors.white70 : AppColors.textTertiary)),
                            const SizedBox(height: 4),
                            Text('${_dates[i]}',
                                style: text.titleMedium?.copyWith(
                                    color: selected ? Colors.white : AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    borderRadius: AppRadius.brLg,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 32),
                      AppSpacing.hGapMd,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today\'s total',
                              style: text.bodySmall?.copyWith(color: Colors.white70)),
                          Text('$_dayCalories kcal',
                              style: text.headlineSmall?.copyWith(color: Colors.white)),
                        ],
                      ),
                      const Spacer(),
                      _MacroChip(label: 'P', value: '72g'),
                      AppSpacing.hGapSm,
                      _MacroChip(label: 'C', value: '168g'),
                      AppSpacing.hGapSm,
                      _MacroChip(label: 'F', value: '62g'),
                    ],
                  ),
                ),
              ),
            ),
            SliverList.list(children: [
              for (final slot in ['Breakfast', 'Lunch', 'Dinner'])
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: _MealSlot(
                    slot: slot,
                    recipe: _plan[slot],
                    onAdd: () {},
                    onRemove: () => setState(() => _plan[slot] = null),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/shopping'),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Generate shopping list'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: AppRadius.brSm,
      ),
      child: Column(
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70)),
          Text(value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _MealSlot extends StatelessWidget {
  final String slot;
  final Recipe? recipe;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _MealSlot({
    required this.slot,
    required this.recipe,
    required this.onAdd,
    required this.onRemove,
  });

  IconData get _icon => switch (slot) {
        'Breakfast' => Icons.wb_sunny_rounded,
        'Lunch' => Icons.lunch_dining_rounded,
        _ => Icons.nightlight_round,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_icon, size: 18, color: AppColors.accent),
            AppSpacing.hGapSm,
            Text(slot, style: text.titleMedium),
          ],
        ),
        AppSpacing.vGapSm,
        if (recipe == null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                borderRadius: AppRadius.brMd,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Add a recipe', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.brSm,
                  child: Image.network(recipe!.imageUrl,
                      width: 56, height: 56, fit: BoxFit.cover),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe!.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                      Text('${recipe!.calories} kcal · ${recipe!.totalMinutes} min',
                          style: text.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
