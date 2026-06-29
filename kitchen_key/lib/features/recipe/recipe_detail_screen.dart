import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock_data.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../shared/widgets/recipe_hero_image.dart';
import '../cooking/cooking_mode_screen.dart';
import '../reviews/reviews_section.dart';
import '../saved/saved_provider.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late int _servings = widget.recipe.servings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Show the summary instantly, then upgrade to the full fetched recipe.
    final detailAsync = ref.watch(recipeDetailProvider(widget.recipe.id));
    final recipe = detailAsync.value ?? widget.recipe;
    final loadingDetail = detailAsync.isLoading && !recipe.hasFullDetail;
    final scale = recipe.servings == 0 ? 1.0 : _servings / recipe.servings;

    final isSaved = ref.watch(savedRecipesProvider).containsKey(recipe.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: _circleButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
            actions: [
              _circleButton(Icons.share_rounded, () {}),
              _circleButton(
                isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                () => ref.read(savedRecipesProvider.notifier).toggle(recipe),
                color: isSaved ? AppColors.coral : null,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: RecipeHeroImage(
                url: recipe.imageUrl,
                heroTag: 'recipe-${recipe.id}',
                scrim: true,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _tagPill(recipe.cuisine),
                      AppSpacing.hGapSm,
                      _tagPill(recipe.mealType, color: AppColors.accentSurface, textColor: AppColors.accentDark),
                      const Spacer(),
                      const Icon(Icons.star_rounded, color: AppColors.rating, size: 18),
                      const SizedBox(width: 4),
                      Text(recipe.rating.toStringAsFixed(1), style: text.titleSmall),
                      Text(' (${recipe.reviewCount})', style: text.bodySmall),
                    ],
                  ),
                  AppSpacing.vGapMd,
                  Text(recipe.title, style: text.headlineMedium),
                  const SizedBox(height: 6),
                  Text(recipe.description, style: text.bodyMedium),
                  if (recipe.country.isNotEmpty || recipe.halalStatus.isNotEmpty) ...[
                    AppSpacing.vGapMd,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (recipe.country.isNotEmpty)
                          _metaChip(Icons.public_rounded, recipe.country),
                        if (recipe.halalStatus.isNotEmpty)
                          _halalChip(recipe.halalStatus),
                      ],
                    ),
                  ],
                  AppSpacing.vGapLg,
                  Row(
                    children: [
                      _infoChip(Icons.schedule_rounded, '${recipe.totalMinutes} min', 'Total'),
                      AppSpacing.hGapMd,
                      _infoChip(Icons.bar_chart_rounded, recipe.difficulty, 'Level'),
                      AppSpacing.hGapMd,
                      _infoChip(Icons.local_fire_department_rounded, '${recipe.calories}', 'kcal'),
                    ],
                  ),
                  AppSpacing.vGapXl,

                  // Nutrition
                  Text('Nutrition per serving', style: text.titleLarge),
                  AppSpacing.vGapMd,
                  _nutritionRow(recipe.nutrition),
                  AppSpacing.vGapXl,

                  // Servings adjuster
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ingredients', style: text.titleLarge),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                        ),
                        child: Row(
                          children: [
                            _stepBtn(Icons.remove_rounded,
                                () => setState(() => _servings = (_servings - 1).clamp(1, 20))),
                            Text('$_servings servings', style: text.titleSmall),
                            _stepBtn(Icons.add_rounded,
                                () => setState(() => _servings = (_servings + 1).clamp(1, 20))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapMd,
                  if (loadingDetail)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else
                    ...recipe.ingredients.map((ing) => _ingredientRow(ing, scale, text)),
                  AppSpacing.vGapXl,

                  // Steps
                  Text('Instructions', style: text.titleLarge),
                  AppSpacing.vGapMd,
                  if (loadingDetail)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else
                    ...List.generate(recipe.steps.length, (i) => _stepRow(i + 1, recipe.steps[i], text)),
                  AppSpacing.vGapXl,

                  // Reviews
                  ReviewsSection(
                    rating: recipe.rating,
                    reviewCount: recipe.reviewCount,
                    reviews: MockData.reviews,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CookingModeScreen(recipe: recipe)),
                ),
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('Start Cooking'),
              ),
            ),
            AppSpacing.hGapMd,
            Container(
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.brMd,
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                tooltip: 'Read aloud',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: color ?? Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _tagPill(String label, {Color? color, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? AppColors.primarySurface,
        borderRadius: AppRadius.brSm,
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor ?? AppColors.primaryDark)),
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.brMd,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(value, style: text.titleSmall),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _nutritionRow(Nutrition n) {
    final items = [
      ('Protein', '${n.proteinG}g', const Color(0xFF3AA0FF)),
      ('Carbs', '${n.carbsG}g', AppColors.accent),
      ('Fat', '${n.fatG}g', AppColors.coral),
      ('Fiber', '${n.fiberG}g', AppColors.primary),
    ];
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: item.$3.withValues(alpha: 0.10),
              borderRadius: AppRadius.brMd,
            ),
            child: Column(
              children: [
                Text(item.$2,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: item.$3)),
                Text(item.$1, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      iconSize: 20,
      icon: Icon(icon, color: AppColors.primary),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _halalChip(String status) {
    final isHalal = status.toLowerCase() == 'halal';
    final isHaram = status.toLowerCase() == 'haram';
    final color = isHalal ? AppColors.success : (isHaram ? AppColors.error : AppColors.warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.brSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isHalal ? Icons.verified_rounded : Icons.info_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(status, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _ingredientRow(RecipeIngredient ing, double scale, TextTheme text) {
    final qty = ing.quantity * scale;
    final qtyLabel = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          AppSpacing.hGapMd,
          Expanded(child: Text(ing.name, style: text.bodyLarge)),
          Text('$qtyLabel ${ing.unit}',
              style: text.titleSmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _stepRow(int number, String step, TextTheme text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            child: Text('$number',
                style: text.labelMedium?.copyWith(color: Colors.white)),
          ),
          AppSpacing.hGapMd,
          Expanded(child: Text(step, style: text.bodyLarge)),
        ],
      ),
    );
  }
}
