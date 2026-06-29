import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../shared/widgets/editorial_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/recipe_card.dart';

class RecipeGenerationScreen extends ConsumerStatefulWidget {
  const RecipeGenerationScreen({super.key});

  @override
  ConsumerState<RecipeGenerationScreen> createState() => _RecipeGenerationScreenState();
}

class _RecipeGenerationScreenState extends ConsumerState<RecipeGenerationScreen> {
  final Set<String> _selected = {};
  final _searchCtrl = TextEditingController();
  String _filter = '';
  List<String>? _submitted; // stable instance passed to the suggest provider

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ingredientsAsync = ref.watch(ingredientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Suggest Recipes')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const EditorialHeader(
                  eyebrow: 'Smart cooking',
                  title: "What's in your fridge?",
                ),
                AppSpacing.vGapSm,
                Text(
                  'Select the ingredients you have and we will suggest recipes you can make right now.',
                  style: text.bodyMedium,
                ),
                AppSpacing.vGapLg,
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _filter = v),
                  decoration: const InputDecoration(
                    hintText: 'Search ingredients…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                AppSpacing.vGapLg,
                if (_selected.isNotEmpty) ...[
                  Text('YOUR BASKET (${_selected.length})',
                      style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
                  AppSpacing.vGapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _selected
                        .map((i) => Chip(
                              label: Text(i),
                              backgroundColor: AppColors.primarySurface,
                              side: BorderSide.none,
                              labelStyle: text.labelMedium?.copyWith(color: AppColors.primaryDark),
                              deleteIconColor: AppColors.primaryDark,
                              onDeleted: () => setState(() => _selected.remove(i)),
                            ))
                        .toList(),
                  ),
                  AppSpacing.vGapLg,
                ],
                Text('SUGGESTED INGREDIENTS',
                    style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
                AppSpacing.vGapSm,
                ingredientsAsync.when(
                  data: (all) {
                    final filtered = all
                        .where((i) => i.toLowerCase().contains(_filter.toLowerCase()))
                        .take(60)
                        .toList();
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: filtered.map((i) {
                        final selected = _selected.contains(i);
                        return FilterChip(
                          label: Text(i),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) => setState(() {
                            selected ? _selected.remove(i) : _selected.add(i);
                          }),
                          labelStyle: text.labelMedium?.copyWith(
                            color: selected ? Colors.white : AppColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                  error: (e, _) => Text(describeApiError(e), style: text.bodyMedium),
                ),

                // Results
                if (_submitted != null) ...[
                  AppSpacing.vGapXl,
                  ref.watch(suggestProvider(_submitted!)).when(
                        data: (results) => results.isEmpty
                            ? const EmptyState(
                                icon: Icons.no_meals_rounded,
                                title: 'No matches',
                                message: 'Try adding a few more ingredients to your basket.',
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  EditorialHeader(
                                    eyebrow: '${results.length} matches',
                                    title: 'You can cook',
                                  ),
                                  AppSpacing.vGapMd,
                                  ...results.asMap().entries.map((e) => Padding(
                                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                        child: _SuggestionCard(
                                          recipe: e.value,
                                          onTap: () => context.push('/recipe', extra: e.value),
                                        ),
                                      ).animate().fadeIn(delay: (e.key * 70).ms).slideY(begin: 0.1, end: 0)),
                                ],
                              ),
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ),
                        error: (e, _) => EmptyState(
                          icon: Icons.cloud_off_rounded,
                          title: 'Connection problem',
                          message: describeApiError(e),
                          actionLabel: 'Retry',
                          onAction: () => ref.invalidate(suggestProvider(_submitted!)),
                        ),
                      ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
            ),
            child: PrimaryButton(
              label: _selected.isEmpty
                  ? 'Select ingredients to start'
                  : 'Suggest from ${_selected.length} ingredient${_selected.length == 1 ? '' : 's'}',
              icon: Icons.auto_awesome_rounded,
              onPressed: _selected.isEmpty
                  ? null
                  : () => setState(() => _submitted = _selected.toList()),
            ),
          ),
        ],
      ),
    );
  }
}

/// A recipe list card with a "match %" badge from the suggestion endpoint.
class _SuggestionCard extends StatelessWidget {
  final dynamic recipe;
  final VoidCallback onTap;
  const _SuggestionCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RecipeListCard(recipe: recipe, onTap: onTap),
        if (recipe.matchScore != null)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.brSm,
              ),
              child: Text('${recipe.matchScore}% match',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.white, letterSpacing: 0)),
            ),
          ),
      ],
    );
  }
}
