import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/recipe_card.dart';
import '../../shared/widgets/skeletons.dart';
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
  String _difficulty = '';
  int? _maxMinutes;
  String _diet = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isFiltering =>
      _query.isNotEmpty || _cuisine != 'All' || _difficulty.isNotEmpty || _maxMinutes != null || _diet.isNotEmpty;

  RecipeQuery get _query0 => RecipeQuery(
        search: _query,
        cuisine: _cuisine,
        difficulty: _difficulty,
        maxMinutes: _maxMinutes,
        diet: _diet,
        limit: 60,
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final saved = ref.watch(savedRecipesProvider);
    final meta = ref.watch(metaProvider);
    final cuisines = <String>[
      'All',
      ...?meta.whenOrNull(data: (m) => (m['cuisines'] as List?)?.map((e) => '$e')),
    ];

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
                      textInputAction: TextInputAction.search,
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
                itemCount: cuisines.length,
                separatorBuilder: (_, _) => AppSpacing.hGapSm,
                itemBuilder: (context, i) {
                  final c = cuisines[i];
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
              child: !_isFiltering
                  ? _buildSuggestions(text, cuisines)
                  : ref.watch(recipeListProvider(_query0)).when(
                        data: (results) => results.isEmpty
                            ? const EmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'No recipes found',
                                message: 'Try a different keyword or filter.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                                itemCount: results.length,
                                separatorBuilder: (_, _) => AppSpacing.vGapMd,
                                itemBuilder: (context, i) {
                                  final r = results[i];
                                  return RecipeListCard(
                                    recipe: r,
                                    isSaved: saved.containsKey(r.id),
                                    onSaveTap: () =>
                                        ref.read(savedRecipesProvider.notifier).toggle(r),
                                    onTap: () => context.push('/recipe', extra: r),
                                  );
                                },
                              ),
                        loading: () => ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                          itemCount: 6,
                          separatorBuilder: (_, _) => AppSpacing.vGapLg,
                          itemBuilder: (_, _) => const RecipeCardSkeleton(),
                        ),
                        error: (e, _) => EmptyState(
                          icon: Icons.cloud_off_rounded,
                          title: 'Connection problem',
                          message: describeApiError(e),
                          actionLabel: 'Retry',
                          onAction: () => ref.invalidate(recipeListProvider(_query0)),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(TextTheme text, List<String> cuisines) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Browse by cuisine', style: text.titleMedium),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: cuisines.where((c) => c != 'All').map((c) {
              return ActionChip(
                label: Text(c),
                onPressed: () => setState(() => _cuisine = c),
              );
            }).toList(),
          ),
          AppSpacing.vGapXl,
          Text('Quick filters', style: text.titleMedium),
          AppSpacing.vGapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(
                  avatar: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Under 30 min'),
                  onPressed: () => setState(() => _maxMinutes = 30)),
              ActionChip(
                  avatar: const Icon(Icons.eco_rounded, size: 16),
                  label: const Text('Vegetarian'),
                  onPressed: () => setState(() => _diet = 'Vegetarian')),
              ActionChip(
                  avatar: const Icon(Icons.star_rounded, size: 16),
                  label: const Text('Easy'),
                  onPressed: () => setState(() => _difficulty = 'Easy')),
            ],
          ),
        ],
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final text = Theme.of(ctx).textTheme;
          Widget group(String title, List<String> options, String current,
              ValueChanged<String> onPick) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                AppSpacing.vGapSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: options.map((o) {
                    final sel = o == current;
                    return FilterChip(
                      label: Text(o),
                      selected: sel,
                      showCheckmark: false,
                      onSelected: (_) => setSheet(() => onPick(sel ? '' : o)),
                      labelStyle: text.labelMedium?.copyWith(
                          color: sel ? Colors.white : AppColors.textSecondary),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filters', style: text.titleLarge),
                AppSpacing.vGapLg,
                group('Diet', const ['Vegetarian', 'Vegan', 'Gluten-Free', 'Keto', 'High-Protein'],
                    _diet, (v) => _diet = v),
                group('Difficulty', const ['Easy', 'Medium', 'Hard'], _difficulty,
                    (v) => _difficulty = v),
                Text('Cooking time', style: text.titleMedium),
                AppSpacing.vGapSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [15, 30, 60].map((m) {
                    final sel = _maxMinutes == m;
                    return FilterChip(
                      label: Text('< $m min'),
                      selected: sel,
                      showCheckmark: false,
                      onSelected: (_) => setSheet(() => _maxMinutes = sel ? null : m),
                      labelStyle: text.labelMedium?.copyWith(
                          color: sel ? Colors.white : AppColors.textSecondary),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapXl,
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text('Apply filters'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
