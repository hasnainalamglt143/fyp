/// A logged meal contributing to the daily nutrition dashboard.
class NutritionEntry {
  final String title;
  final String meal; // Breakfast / Lunch / Dinner / Snack
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  const NutritionEntry({
    required this.title,
    required this.meal,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

/// An item on the shopping list, grouped by store aisle.
class ShoppingItem {
  final String name;
  final String quantity;
  final String aisle; // Produce / Dairy / Meat / Pantry / Bakery
  bool checked;

  ShoppingItem({
    required this.name,
    required this.quantity,
    required this.aisle,
    this.checked = false,
  });
}
