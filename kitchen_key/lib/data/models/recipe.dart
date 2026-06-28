/// Core domain model for a recipe. Mirrors the fields the Django/DRF backend
/// will expose so the UI can later swap mock data for the real API with no
/// widget changes.
class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String cuisine;
  final String mealType;
  final String difficulty; // Easy | Medium | Hard
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final double rating;
  final int reviewCount;
  final int calories;
  final List<String> dietTags;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final Nutrition nutrition;
  final String authorName;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.cuisine,
    required this.mealType,
    required this.difficulty,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.servings,
    required this.rating,
    required this.reviewCount,
    required this.calories,
    required this.dietTags,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    required this.authorName,
  });

  int get totalMinutes => prepMinutes + cookMinutes;
}

class RecipeIngredient {
  final String name;
  final double quantity;
  final String unit;

  const RecipeIngredient(this.name, this.quantity, this.unit);
}

class Nutrition {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int fiberG;
  final int sugarG;

  const Nutrition({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sugarG,
  });
}
