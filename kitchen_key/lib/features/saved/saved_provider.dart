import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recipe.dart';

/// Holds saved recipes (full objects) in memory, keyed by id. Will later be
/// backed by the backend + a local Hive cache for offline access.
class SavedRecipesNotifier extends Notifier<Map<String, Recipe>> {
  @override
  Map<String, Recipe> build() => {};

  void toggle(Recipe recipe) {
    final next = {...state};
    if (next.containsKey(recipe.id)) {
      next.remove(recipe.id);
    } else {
      next[recipe.id] = recipe;
    }
    state = next;
  }

  bool isSaved(String id) => state.containsKey(id);
}

final savedRecipesProvider =
    NotifierProvider<SavedRecipesNotifier, Map<String, Recipe>>(SavedRecipesNotifier.new);

/// The saved recipes as a list (newest first).
final savedRecipeListProvider = Provider<List<Recipe>>((ref) {
  return ref.watch(savedRecipesProvider).values.toList().reversed.toList();
});
