import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../models/recipe.dart';

/// Immutable query for the recipe list endpoint.
class RecipeQuery {
  final String search;
  final String cuisine;
  final String mealType;
  final String difficulty;
  final String diet;
  final int? maxMinutes;
  final String sort;
  final int limit;

  const RecipeQuery({
    this.search = '',
    this.cuisine = '',
    this.mealType = '',
    this.difficulty = '',
    this.diet = '',
    this.maxMinutes,
    this.sort = 'name',
    this.limit = 40,
  });

  Map<String, dynamic> toParams() => {
        if (search.isNotEmpty) 'search': search,
        if (cuisine.isNotEmpty && cuisine != 'All') 'cuisine': cuisine,
        if (mealType.isNotEmpty) 'meal_type': mealType,
        if (difficulty.isNotEmpty) 'difficulty': difficulty,
        if (diet.isNotEmpty) 'diet': diet,
        if (maxMinutes != null) 'max_minutes': maxMinutes,
        'sort': sort,
        'limit': limit,
      };

  @override
  bool operator ==(Object other) =>
      other is RecipeQuery &&
      other.search == search &&
      other.cuisine == cuisine &&
      other.mealType == mealType &&
      other.difficulty == difficulty &&
      other.diet == diet &&
      other.maxMinutes == maxMinutes &&
      other.sort == sort &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(search, cuisine, mealType, difficulty, diet, maxMinutes, sort, limit);
}

/// Talks to the Kitchen Key `/api/v1` backend.
class RecipeRepository {
  final Dio _dio;
  RecipeRepository(this._dio);

  Future<List<Recipe>> getRecipes(RecipeQuery query) async {
    final res = await _dio.get('/recipes/', queryParameters: query.toParams());
    final results = (res.data['results'] as List? ?? const []);
    return results.map((e) => Recipe.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<Recipe> getRecipe(String id) async {
    final res = await _dio.get('/recipes/$id/');
    return Recipe.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<List<Recipe>> suggestByIngredients(List<String> ingredients) async {
    final res = await _dio.post('/recipes/suggest/', data: {'ingredients': ingredients});
    final results = (res.data['results'] as List? ?? const []);
    return results.map((e) => Recipe.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<List<String>> getIngredients() async {
    final res = await _dio.get('/ingredients/');
    return (res.data['ingredients'] as List? ?? const []).map((e) => '$e').toList();
  }

  Future<Map<String, dynamic>> getMeta() async {
    final res = await _dio.get('/meta/');
    return (res.data as Map).cast<String, dynamic>();
  }
}

// ---- Providers ----

final recipeRepositoryProvider =
    Provider<RecipeRepository>((ref) => RecipeRepository(ref.watch(dioProvider)));

/// Recipe list for a given query (Home uses the default; Search varies it).
final recipeListProvider =
    FutureProvider.autoDispose.family<List<Recipe>, RecipeQuery>((ref, query) {
  return ref.watch(recipeRepositoryProvider).getRecipes(query);
});

/// Full recipe detail by id.
final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe, String>((ref, id) {
  return ref.watch(recipeRepositoryProvider).getRecipe(id);
});

/// Ingredient vocabulary for the "what's in your fridge" picker.
final ingredientsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(recipeRepositoryProvider).getIngredients();
});

/// Filter metadata (cuisines, meal types, diets, …).
final metaProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(recipeRepositoryProvider).getMeta();
});

/// Ingredient-based suggestions for a selected basket.
final suggestProvider =
    FutureProvider.autoDispose.family<List<Recipe>, List<String>>((ref, ingredients) {
  return ref.watch(recipeRepositoryProvider).suggestByIngredients(ingredients);
});
