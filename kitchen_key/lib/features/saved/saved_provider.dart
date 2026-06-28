import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_data.dart';
import '../../data/models/recipe.dart';

/// Holds the set of saved recipe IDs in memory. Will later be backed by the
/// Django API + a local Hive cache for offline access.
class SavedRecipesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'3', '6'};

  void toggle(String id) {
    final next = {...state};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
  }

  bool isSaved(String id) => state.contains(id);
}

final savedRecipesProvider =
    NotifierProvider<SavedRecipesNotifier, Set<String>>(SavedRecipesNotifier.new);

/// Resolves the saved IDs into full [Recipe] objects.
final savedRecipeListProvider = Provider<List<Recipe>>((ref) {
  final ids = ref.watch(savedRecipesProvider);
  return MockData.recipes.where((r) => ids.contains(r.id)).toList();
});
