import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../shared/widgets/editorial_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/recipe_card.dart';
import '../../shared/widgets/recipe_hero_image.dart';
import '../../shared/widgets/skeletons.dart';
import '../saved/saved_provider.dart';

const _homeQuery = RecipeQuery(sort: 'name', limit: 40);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recipeListProvider(_homeQuery));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.refresh(recipeListProvider(_homeQuery).future),
          child: async.when(
            data: (recipes) => _content(context, ref, recipes),
            loading: () => const _HomeLoading(),
            error: (e, _) => _HomeError(message: describeApiError(e), onRetry: () {
              ref.invalidate(recipeListProvider(_homeQuery));
            }),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, List<Recipe> recipes) {
    final text = Theme.of(context).textTheme;
    final saved = ref.watch(savedRecipesProvider);

    void openRecipe(Recipe r) => context.push('/recipe', extra: r);
    void toggleSave(Recipe r) => ref.read(savedRecipesProvider.notifier).toggle(r);

    if (recipes.isEmpty) {
      return ListView(children: [
        const _Greeting(),
        const SizedBox(height: 80),
        const EmptyState(
          icon: Icons.ramen_dining_rounded,
          title: 'No recipes yet',
          message: 'Once your backend has recipes, they will appear here.',
        ),
      ]);
    }

    final featured = recipes.take(6).toList();
    final dayRecipe = recipes.first;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _Greeting()),

        // Recipe of the day
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
            child: GestureDetector(
              onTap: () => openRecipe(dayRecipe),
              child: ClipRRect(
                borderRadius: AppRadius.brLg,
                child: SizedBox(
                  height: 340,
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
                                  color: AppColors.accent, borderRadius: AppRadius.brSm),
                              child: Text('RECIPE OF THE DAY',
                                  style: AppTypography.eyebrow(context, color: Colors.white)),
                            ),
                            AppSpacing.vGapMd,
                            Text(dayRecipe.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: text.displaySmall?.copyWith(color: Colors.white)),
                            const SizedBox(height: 6),
                            Text(
                              [
                                if (dayRecipe.cuisine.isNotEmpty) dayRecipe.cuisine,
                                if (dayRecipe.totalMinutes > 0) '${dayRecipe.totalMinutes} min',
                                if (dayRecipe.calories > 0) '${dayRecipe.calories} kcal',
                              ].join('  ·  '),
                              style: text.bodyMedium?.copyWith(color: Colors.white70),
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

        // Generate CTA
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
                          Text('Suggest recipes from your ingredients',
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
            child: const EditorialHeader(eyebrow: 'Fresh from the kitchen', title: 'Featured'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 340,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: featured.length,
              separatorBuilder: (_, _) => AppSpacing.hGapMd,
              itemBuilder: (context, i) {
                final r = featured[i];
                return FeaturedRecipeCard(
                  recipe: r,
                  isSaved: saved.containsKey(r.id),
                  onSaveTap: () => toggleSave(r),
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
            child: const EditorialHeader(eyebrow: 'Browse all', title: 'Recipes'),
          ),
        ),
        SliverList.separated(
          itemCount: recipes.length,
          separatorBuilder: (_, _) => AppSpacing.vGapMd,
          itemBuilder: (context, i) {
            final r = recipes[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: RecipeListCard(
                recipe: r,
                isSaved: saved.containsKey(r.id),
                onSaveTap: () => toggleSave(r),
                onTap: () => openRecipe(r),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
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
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySurface,
            child: Icon(Icons.person_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const _Greeting(),
        AppSpacing.vGapLg,
        const SkeletonBox(height: 340, radius: AppRadius.brLg),
        AppSpacing.vGapLg,
        const SkeletonBox(height: 80, radius: AppRadius.brLg),
        AppSpacing.vGapLg,
        for (var i = 0; i < 4; i++) ...[
          const RecipeCardSkeleton(),
          AppSpacing.vGapLg,
        ],
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _HomeError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _Greeting(),
        const SizedBox(height: 60),
        EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Connection problem',
          message: message,
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      ],
    );
  }
}
