/// Core domain model for a recipe. Maps the Django/DRF backend JSON
/// (`/api/v1/recipes/...`) into a shape the UI widgets already consume.
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

  // New fields from the LLM-collected dataset.
  final String country;
  final String halalStatus; // Halal | Haram | Mashbooh
  final String halalReason;
  final List<String> allergens;
  final int? matchScore; // 0-100, only set by the ingredient-suggestion endpoint

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
    this.country = '',
    this.halalStatus = '',
    this.halalReason = '',
    this.allergens = const [],
    this.matchScore,
  });

  int get totalMinutes => prepMinutes + cookMinutes;

  bool get hasFullDetail => ingredients.isNotEmpty && steps.isNotEmpty;

  /// Builds a Recipe from either a summary or a full detail JSON object.
  factory Recipe.fromJson(Map<String, dynamic> j) {
    final nut = (j['nutrition_per_serving'] as Map?)?.cast<String, dynamic>() ?? const {};

    var prep = _toInt(j['prep_time_minutes']);
    var cook = _toInt(j['cook_time_minutes']);
    final total = _toInt(j['total_time_minutes']);
    if (prep == 0 && cook == 0 && total > 0) cook = total;

    final calories = j['calories'] != null ? _toInt(j['calories']) : _toInt(nut['calories']);

    return Recipe(
      id: '${j['id']}',
      title: _titleCase('${j['name'] ?? ''}'),
      description: '${j['description'] ?? ''}',
      imageUrl: _imageFor(j),
      cuisine: '${j['cuisine'] ?? ''}',
      mealType: '${j['meal_type'] ?? ''}',
      difficulty: '${j['difficulty'] ?? ''}',
      prepMinutes: prep,
      cookMinutes: cook,
      servings: _toInt(j['servings'], 1),
      rating: _toDouble(j['rating']),
      reviewCount: _toInt(j['review_count']),
      calories: calories,
      dietTags: _toStringList(j['diet_flags']),
      ingredients: ((j['ingredients'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => RecipeIngredient(
                '${e['name'] ?? ''}',
                _toDouble(e['quantity'], 1),
                '${e['unit'] ?? ''}',
              ))
          .toList(),
      steps: _toStringList(j['steps']),
      nutrition: Nutrition(
        calories: _toInt(nut['calories']),
        proteinG: _toInt(nut['protein_g']),
        carbsG: _toInt(nut['carbs_g']),
        fatG: _toInt(nut['fat_g']),
        fiberG: _toInt(nut['fiber_g']),
        sugarG: _toInt(nut['sugar_g']),
      ),
      authorName: '${j['author'] ?? 'AI-generated'}',
      country: '${j['country'] ?? ''}',
      halalStatus: '${j['halal_haram_status'] ?? ''}',
      halalReason: '${j['halal_haram_reason'] ?? ''}',
      allergens: _toStringList(j['allergens']),
      matchScore: j['match_score'] != null ? _toInt(j['match_score']) : null,
    );
  }

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

// ---- JSON helpers ----

int _toInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9-]'), '')) ?? fallback;
  return fallback;
}

double _toDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? fallback;
  return fallback;
}

List<String> _toStringList(dynamic v) =>
    v is List ? v.map((e) => '$e').where((e) => e.isNotEmpty).toList() : const [];

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// The dataset's `image_url` is usually blank (an LLM can't supply real photos),
/// so we fall back to a keyword food photo that stays stable per recipe id.
String _imageFor(Map<String, dynamic> j) {
  final url = '${j['image_url'] ?? ''}'.trim();
  if (url.isNotEmpty) return url;
  final query = '${j['image_query'] ?? j['name'] ?? 'food'}';
  final keywords = query.split(RegExp(r'\s+')).take(2).join(',');
  final lock = j['id'] ?? 0;
  return 'https://loremflickr.com/600/400/${Uri.encodeComponent(keywords)},food?lock=$lock';
}
