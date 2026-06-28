import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock_data.dart';
import '../../data/models/meal_entities.dart';

/// In-memory shopping list state (generated from the meal plan).
class ShoppingListNotifier extends Notifier<List<ShoppingItem>> {
  @override
  List<ShoppingItem> build() => MockData.shoppingList();

  void toggle(ShoppingItem item) {
    item.checked = !item.checked;
    state = [...state];
  }

  void add(String name, String aisle) {
    state = [...state, ShoppingItem(name: name, quantity: '1', aisle: aisle)];
  }

  void remove(ShoppingItem item) {
    state = state.where((i) => i != item).toList();
  }

  void clearChecked() {
    state = state.where((i) => !i.checked).toList();
  }
}

final shoppingListProvider =
    NotifierProvider<ShoppingListNotifier, List<ShoppingItem>>(ShoppingListNotifier.new);

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  static const _aisleIcons = {
    'Produce': Icons.eco_rounded,
    'Dairy': Icons.egg_rounded,
    'Meat': Icons.set_meal_rounded,
    'Pantry': Icons.kitchen_rounded,
    'Bakery': Icons.bakery_dining_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final items = ref.watch(shoppingListProvider);
    final checked = items.where((i) => i.checked).length;
    final progress = items.isEmpty ? 0.0 : checked / items.length;

    // Group by aisle
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.aisle, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: AppRadius.brLg,
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$checked of ${items.length} items',
                        style: text.titleMedium?.copyWith(color: Colors.white)),
                    Text('${(progress * 100).round()}%',
                        style: text.titleLarge?.copyWith(color: Colors.white)),
                  ],
                ),
                AppSpacing.vGapSm,
                ClipRRect(
                  borderRadius: AppRadius.brPill,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(_aisleIcons[entry.key] ?? Icons.shopping_bag_rounded,
                            size: 18, color: AppColors.accent),
                        AppSpacing.hGapSm,
                        Text(entry.key.toUpperCase(),
                            style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  ...entry.value.map((item) => _ShoppingTile(
                        item: item,
                        onToggle: () => ref.read(shoppingListProvider.notifier).toggle(item),
                        onDismiss: () => ref.read(shoppingListProvider.notifier).remove(item),
                      )),
                  AppSpacing.vGapSm,
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add item'),
      ),
    );
  }

  void _addItem(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add custom item', style: Theme.of(ctx).textTheme.titleLarge),
            AppSpacing.vGapLg,
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. Olive oil'),
            ),
            AppSpacing.vGapLg,
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(shoppingListProvider.notifier).add(controller.text.trim(), 'Pantry');
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add to list'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDismiss;

  const _ShoppingTile({
    required this.item,
    required this.onToggle,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Dismissible(
      key: ValueKey(item.hashCode),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: AppRadius.brMd),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadius.brMd,
          child: InkWell(
            onTap: onToggle,
            borderRadius: AppRadius.brMd,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    item.checked
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: item.checked ? AppColors.primary : AppColors.textTertiary,
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Text(
                      item.name,
                      style: text.titleSmall?.copyWith(
                        decoration: item.checked ? TextDecoration.lineThrough : null,
                        color: item.checked ? AppColors.textTertiary : null,
                      ),
                    ),
                  ),
                  Text(item.quantity, style: text.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
