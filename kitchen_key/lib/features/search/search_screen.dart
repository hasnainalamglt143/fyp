import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock_data.dart';
import '../../data/models/recipe.dart';
import '../../shared/widgets/recipe_card.dart';
import '../saved/saved_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String _cuisine = 'All';

  static const _recentSearches = ['Biryani', 'Pasta', 'Smoothie', 'Tacos'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Recipe> get _results {
    return MockData.recipes.where((r) {
      final matchesQuery = _query.isEmpty ||
          r.title.toLowerCase().contains(_query.toLowerCase()) ||
          r.ingredients.any((i) => i.name.toLowerCase().contains(_query.toLowerCase()));
      final matchesCuisine = _cuisine == 'All' || r.cuisine == _cuisine;
      return matchesQuery && matchesCuisine;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final saved = ref.watch(savedRecipesProvider);
    final results = _results;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Text('Search', style: text.headlineMedium),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Recipe or ingredient…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  GestureDetector(
                    onTap: _openFilters,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: MockData.cuisines.length,
                separatorBuilder: (_, _) => AppSpacing.hGapSm,
                itemBuilder: (context, i) {
                  final c = MockData.cuisines[i];
                  final selected = c == _cuisine;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => setState(() => _cuisine = c),
                    labelStyle: text.labelMedium?.copyWith(
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            AppSpacing.vGapMd,
            Expanded(
              child: _query.isEmpty && _cuisine == 'All'
                  ? _buildSuggestions(text)
                  : results.isEmpty
                      ? _buildEmpty(text)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                          itemCount: results.length,
                          separatorBuilder: (_, _) => AppSpacing.vGapMd,
                          itemBuilder: (context, i) {
                            final r = results[i];
                            return RecipeListCard(
                              recipe: r,
                              isSaved: saved.contains(r.id),
                              onSaveTap: () =>
                                  ref.read(savedRecipesProvider.notifier).toggle(r.id),
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

  Widget _buildSuggestions(TextTheme text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent searches', style: text.titleMedium),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _recentSearches
                .map((s) => ActionChip(
                      avatar: const Icon(Icons.history_rounded, size: 16),
                      label: Text(s),
                      onPressed: () {
                        _controller.text = s;
                        setState(() => _query = s);
                      },
                    ))
                .toList(),
          ),
          AppSpacing.vGapXl,
          Text('Popular right now', style: text.titleMedium),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: ['Quick dinners', 'Healthy', 'Desserts', 'Under 30 min', 'High protein']
                .map((s) => Chip(
                      backgroundColor: AppColors.primarySurface,
                      side: BorderSide.none,
                      label: Text(s, style: text.labelMedium?.copyWith(color: AppColors.primaryDark)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(TextTheme text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textTertiary),
          AppSpacing.vGapMd,
          Text('No recipes found', style: text.titleMedium),
          const SizedBox(height: 4),
          Text('Try a different keyword or filter', style: text.bodyMedium),
        ],
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FilterSheet(),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: AppRadius.brSm),
            ),
          ),
          AppSpacing.vGapLg,
          Text('Filters', style: text.titleLarge),
          AppSpacing.vGapLg,
          Text('Diet', style: text.titleMedium),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: MockData.dietFilters
                .map((d) => FilterChip(label: Text(d), selected: false, onSelected: (_) {}))
                .toList(),
          ),
          AppSpacing.vGapLg,
          Text('Cooking time', style: text.titleMedium),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: ['< 15 min', '< 30 min', '< 1 hr', '> 1 hr']
                .map((d) => FilterChip(label: Text(d), selected: false, onSelected: (_) {}))
                .toList(),
          ),
          AppSpacing.vGapLg,
          Text('Difficulty', style: text.titleMedium),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: ['Easy', 'Medium', 'Hard']
                .map((d) => FilterChip(label: Text(d), selected: false, onSelected: (_) {}))
                .toList(),
          ),
          AppSpacing.vGapXl,
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
