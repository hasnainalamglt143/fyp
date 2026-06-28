import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../data/models/recipe.dart';
import '../../shared/widgets/editorial_header.dart';
import '../../shared/widgets/recipe_card.dart';
import '../../shared/widgets/recipe_hero_image.dart';
import '../saved/saved_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final saved = ref.watch(savedRecipesProvider);
    final dayRecipe = MockData.recipeOfTheDay;

    void openRecipe(Recipe r) => context.push('/recipe', extra: r);
    void toggleSave(String id) => ref.read(savedRecipesProvider.notifier).toggle(id);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Greeting
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GOOD MORNING',
                              style: AppTypography.eyebrow(context, color: AppColors.accent)),
                          const SizedBox(height: 4),
                          Text('Let’s cook something', style: text.headlineSmall),
                        ],
                      ),
                    ),
                    _circleIcon(context, Icons.notifications_none_rounded, badge: true),
                    AppSpacing.hGapSm,
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primarySurface,
                      child: Icon(Icons.person_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),

            // Search field (decorative entry)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppRadius.brMd,
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                      AppSpacing.hGapMd,
                      Text('Search recipes, ingredients…',
                          style: text.bodyMedium?.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ),
            ),

            // Recipe of the day — editorial hero
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                child: GestureDetector(
                  onTap: () => openRecipe(dayRecipe),
                  child: ClipRRect(
                    borderRadius: AppRadius.brLg,
                    child: SizedBox(
                      height: 360,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RecipeHeroImage(url: dayRecipe.imageUrl, scrim: true),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: AppRadius.brSm,
                                  ),
                                  child: Text('RECIPE OF THE DAY',
                                      style: AppTypography.eyebrow(context, color: Colors.white)),
                                ),
                                AppSpacing.vGapMd,
                                Text(dayRecipe.title,
                                    style: text.displaySmall?.copyWith(color: Colors.white)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: AppColors.rating, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${dayRecipe.rating}  ·  ${dayRecipe.totalMinutes} min  ·  ${dayRecipe.calories} kcal',
                                        style: text.bodyMedium?.copyWith(color: Colors.white70)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: MockData.categories.length,
                    separatorBuilder: (_, _) => AppSpacing.hGapSm,
                    itemBuilder: (context, i) {
                      final selected = i == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Theme.of(context).colorScheme.surface,
                          borderRadius: AppRadius.brPill,
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Text(MockData.categories[i],
                            style: text.labelMedium?.copyWith(
                              color: selected ? Colors.white : AppColors.textSecondary,
                            )),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Generate CTA banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                child: GestureDetector(
                  onTap: () => context.push('/generate'),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient,
                      borderRadius: AppRadius.brLg,
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("What's in your fridge?",
                                  style: text.titleMedium?.copyWith(color: Colors.white)),
                              Text('Generate a recipe from your ingredients',
                                  style: text.bodySmall?.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Trending carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
                child: EditorialHeader(
                  eyebrow: 'Hot right now',
                  title: 'Trending',
                  actionLabel: 'See all',
                  onAction: () {},
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 340,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: MockData.trending.length,
                  separatorBuilder: (_, _) => AppSpacing.hGapMd,
                  itemBuilder: (context, i) {
                    final r = MockData.trending[i];
                    return FeaturedRecipeCard(
                      recipe: r,
                      isSaved: saved.contains(r.id),
                      onSaveTap: () => toggleSave(r.id),
                      onTap: () => openRecipe(r),
                    );
                  },
                ),
              ),
            ),

            // Recommended
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
                child: EditorialHeader(eyebrow: 'Picked for you', title: 'Recommended'),
              ),
            ),
            SliverList.separated(
              itemCount: MockData.recipes.length,
              separatorBuilder: (_, _) => AppSpacing.vGapMd,
              itemBuilder: (context, i) {
                final r = MockData.recipes[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: RecipeListCard(
                    recipe: r,
                    heroTag: 'recipe-${r.id}',
                    isSaved: saved.contains(r.id),
                    onSaveTap: () => toggleSave(r.id),
                    onTap: () => openRecipe(r),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(BuildContext context, IconData icon, {bool badge = false}) {
    return Stack(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          shape: const CircleBorder(),
          child: IconButton(onPressed: () {}, icon: Icon(icon)),
        ),
        if (badge)
          const Positioned(
            right: 10,
            top: 10,
            child: CircleAvatar(radius: 4, backgroundColor: AppColors.coral),
          ),
      ],
    );
  }
}
