import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock_data.dart';
import '../../data/models/recipe.dart';
import '../../shared/widgets/editorial_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/recipe_card.dart';

/// "What's in your fridge?" — pick ingredients, generate matching recipes.
class RecipeGenerationScreen extends ConsumerStatefulWidget {
  const RecipeGenerationScreen({super.key});

  @override
  ConsumerState<RecipeGenerationScreen> createState() => _RecipeGenerationScreenState();
}

class _RecipeGenerationScreenState extends ConsumerState<RecipeGenerationScreen> {
  final Set<String> _selected = {};
  final _searchCtrl = TextEditingController();
  String _filter = '';
  bool _generated = false;
  bool _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filteredPantry => MockData.pantry
      .where((i) => i.toLowerCase().contains(_filter.toLowerCase()))
      .toList();

  List<Recipe> get _results => MockData.recipes;

  void _generate() {
    setState(() {
      _loading = true;
      _generated = false;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _loading = false;
          _generated = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Recipe')),
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
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _filteredPantry.map((i) {
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
                ),
                if (_loading) ...[
                  AppSpacing.vGapXl,
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  AppSpacing.vGapMd,
                  Center(child: Text('Finding recipes…', style: text.bodyMedium)),
                ],
                if (_generated) ...[
                  AppSpacing.vGapXl,
                  EditorialHeader(
                    eyebrow: '${_results.length} matches',
                    title: 'You can cook',
                  ),
                  AppSpacing.vGapMd,
                  if (_results.isEmpty)
                    const EmptyState(
                      icon: Icons.no_meals_rounded,
                      title: 'No matches',
                      message: 'Try adding a few more ingredients to your basket.',
                    )
                  else
                    ..._results.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: RecipeListCard(
                            recipe: e.value,
                            onTap: () => context.push('/recipe', extra: e.value),
                          ),
                        ).animate().fadeIn(delay: (e.key * 80).ms).slideY(begin: 0.1, end: 0)),
                ],
              ],
            ),
          ),
          // Generate button
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
            ),
            child: PrimaryButton(
              label: _selected.isEmpty
                  ? 'Select ingredients to start'
                  : 'Generate ${_selected.length}-ingredient recipes',
              icon: Icons.auto_awesome_rounded,
              onPressed: _selected.isEmpty ? null : _generate,
            ),
          ),
        ],
      ),
    );
  }
}
