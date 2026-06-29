import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/recipe_card.dart';
import 'saved_provider.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final saved = ref.watch(savedRecipeListProvider);
    final savedIds = ref.watch(savedRecipesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saved Recipes', style: text.headlineMedium),
                  Text('${saved.length} items', style: text.bodyMedium),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  for (final c in ['All', 'Favourites', 'Want to try', 'Made before'])
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: c == 'All',
                        onSelected: (_) {},
                        labelStyle: text.labelMedium?.copyWith(
                          color: c == 'All' ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.vGapMd,
            Expanded(
              child: saved.isEmpty
                  ? _buildEmpty(context, text)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                      itemCount: saved.length,
                      separatorBuilder: (_, _) => AppSpacing.vGapMd,
                      itemBuilder: (context, i) {
                        final r = saved[i];
                        return RecipeListCard(
                          recipe: r,
                          isSaved: savedIds.containsKey(r.id),
                          onSaveTap: () =>
                              ref.read(savedRecipesProvider.notifier).toggle(r),
                          onTap: () => context.push('/recipe', extra: r),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, TextTheme text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border_rounded,
                  size: 56, color: AppColors.primary),
            ),
            AppSpacing.vGapLg,
            Text('No saved recipes yet', style: text.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Tap the heart on any recipe to keep it here for later.',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
