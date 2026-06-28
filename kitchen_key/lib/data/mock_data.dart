import 'models/recipe.dart';
import 'models/review.dart';
import 'models/meal_entities.dart';

/// Sample data used while the UI is being built ahead of the Django backend.
/// Images are royalty-free Unsplash food photos (loaded via cached_network_image).
class MockData {
  MockData._();

  static const List<String> cuisines = [
    'All', 'Pakistani', 'Italian', 'Chinese', 'Indian', 'Mexican', 'Thai', 'Continental',
  ];

  static const List<String> categories = [
    'Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Dessert', 'Drinks',
  ];

  static const List<String> dietFilters = [
    'Vegetarian', 'Vegan', 'Gluten-Free', 'Keto', 'High-Protein', 'Low-Carb',
  ];

  static final List<Recipe> recipes = [
    Recipe(
      id: '1',
      title: 'Chicken Biryani',
      description:
          'Fragrant basmati rice layered with spiced chicken, caramelised onions and saffron. A celebration in a pot.',
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800&q=80',
      cuisine: 'Pakistani',
      mealType: 'Dinner',
      difficulty: 'Medium',
      prepMinutes: 25,
      cookMinutes: 45,
      servings: 4,
      rating: 4.8,
      reviewCount: 312,
      calories: 540,
      dietTags: ['High-Protein'],
      authorName: 'Ayesha K.',
      ingredients: [
        RecipeIngredient('Basmati rice', 2, 'cups'),
        RecipeIngredient('Chicken', 500, 'g'),
        RecipeIngredient('Onion', 2, 'large'),
        RecipeIngredient('Yogurt', 1, 'cup'),
        RecipeIngredient('Biryani masala', 2, 'tbsp'),
        RecipeIngredient('Saffron', 1, 'pinch'),
      ],
      steps: [
        'Marinate chicken in yogurt and biryani masala for 30 minutes.',
        'Fry sliced onions until golden and crisp, then set aside.',
        'Par-boil the soaked basmati rice with whole spices.',
        'Cook the marinated chicken until tender and the oil separates.',
        'Layer rice over chicken, add saffron milk and fried onions.',
        'Cover and steam (dum) on low heat for 20 minutes. Serve hot.',
      ],
      nutrition: Nutrition(calories: 540, proteinG: 32, carbsG: 58, fatG: 18, fiberG: 4, sugarG: 6),
    ),
    Recipe(
      id: '2',
      title: 'Creamy Tuscan Pasta',
      description:
          'Silky garlic-parmesan sauce with sun-dried tomatoes and spinach tossed through al dente penne.',
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
      cuisine: 'Italian',
      mealType: 'Lunch',
      difficulty: 'Easy',
      prepMinutes: 10,
      cookMinutes: 20,
      servings: 3,
      rating: 4.6,
      reviewCount: 198,
      calories: 620,
      dietTags: ['Vegetarian'],
      authorName: 'Marco R.',
      ingredients: [
        RecipeIngredient('Penne pasta', 300, 'g'),
        RecipeIngredient('Heavy cream', 1, 'cup'),
        RecipeIngredient('Parmesan', 0.5, 'cup'),
        RecipeIngredient('Sun-dried tomatoes', 0.5, 'cup'),
        RecipeIngredient('Spinach', 2, 'cups'),
        RecipeIngredient('Garlic', 3, 'cloves'),
      ],
      steps: [
        'Cook penne until al dente, reserve a little pasta water.',
        'Sauté garlic, then add sun-dried tomatoes.',
        'Pour in cream and simmer, then stir in parmesan.',
        'Fold in spinach until wilted.',
        'Toss pasta through the sauce, loosen with pasta water and serve.',
      ],
      nutrition: Nutrition(calories: 620, proteinG: 19, carbsG: 72, fatG: 28, fiberG: 5, sugarG: 8),
    ),
    Recipe(
      id: '3',
      title: 'Avocado Berry Bowl',
      description:
          'A vibrant breakfast bowl with creamy avocado, fresh berries, granola and a drizzle of honey.',
      imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80',
      cuisine: 'Continental',
      mealType: 'Breakfast',
      difficulty: 'Easy',
      prepMinutes: 10,
      cookMinutes: 0,
      servings: 1,
      rating: 4.9,
      reviewCount: 421,
      calories: 320,
      dietTags: ['Vegan', 'Gluten-Free'],
      authorName: 'Hana M.',
      ingredients: [
        RecipeIngredient('Avocado', 1, 'whole'),
        RecipeIngredient('Mixed berries', 1, 'cup'),
        RecipeIngredient('Granola', 0.5, 'cup'),
        RecipeIngredient('Almond milk', 0.5, 'cup'),
        RecipeIngredient('Honey', 1, 'tbsp'),
      ],
      steps: [
        'Blend avocado with almond milk until smooth.',
        'Pour into a bowl as the base.',
        'Top with berries and granola.',
        'Finish with a drizzle of honey and serve chilled.',
      ],
      nutrition: Nutrition(calories: 320, proteinG: 8, carbsG: 38, fatG: 16, fiberG: 11, sugarG: 18),
    ),
    Recipe(
      id: '4',
      title: 'Spicy Beef Tacos',
      description:
          'Soft tortillas loaded with seasoned beef, fresh salsa, crunchy lettuce and a squeeze of lime.',
      imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&q=80',
      cuisine: 'Mexican',
      mealType: 'Dinner',
      difficulty: 'Easy',
      prepMinutes: 15,
      cookMinutes: 15,
      servings: 4,
      rating: 4.7,
      reviewCount: 256,
      calories: 480,
      dietTags: ['High-Protein'],
      authorName: 'Diego S.',
      ingredients: [
        RecipeIngredient('Ground beef', 400, 'g'),
        RecipeIngredient('Taco shells', 8, 'pcs'),
        RecipeIngredient('Tomato', 2, 'medium'),
        RecipeIngredient('Lettuce', 1, 'cup'),
        RecipeIngredient('Taco seasoning', 2, 'tbsp'),
        RecipeIngredient('Lime', 1, 'whole'),
      ],
      steps: [
        'Brown the beef and stir in taco seasoning.',
        'Dice tomatoes and shred lettuce for toppings.',
        'Warm the taco shells.',
        'Fill with beef and fresh toppings, squeeze lime and serve.',
      ],
      nutrition: Nutrition(calories: 480, proteinG: 28, carbsG: 36, fatG: 24, fiberG: 6, sugarG: 4),
    ),
    Recipe(
      id: '5',
      title: 'Thai Green Curry',
      description:
          'Aromatic coconut curry with crisp vegetables and basil, simmered in a homemade green curry paste.',
      imageUrl: 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800&q=80',
      cuisine: 'Thai',
      mealType: 'Dinner',
      difficulty: 'Medium',
      prepMinutes: 20,
      cookMinutes: 25,
      servings: 4,
      rating: 4.5,
      reviewCount: 173,
      calories: 410,
      dietTags: ['Vegan', 'Gluten-Free'],
      authorName: 'Suda P.',
      ingredients: [
        RecipeIngredient('Coconut milk', 400, 'ml'),
        RecipeIngredient('Green curry paste', 3, 'tbsp'),
        RecipeIngredient('Mixed vegetables', 3, 'cups'),
        RecipeIngredient('Tofu', 200, 'g'),
        RecipeIngredient('Thai basil', 0.5, 'cup'),
      ],
      steps: [
        'Fry the curry paste until fragrant.',
        'Add coconut milk and bring to a gentle simmer.',
        'Add vegetables and tofu, cook until tender.',
        'Stir through basil and serve with jasmine rice.',
      ],
      nutrition: Nutrition(calories: 410, proteinG: 14, carbsG: 30, fatG: 26, fiberG: 7, sugarG: 9),
    ),
    Recipe(
      id: '6',
      title: 'Chocolate Lava Cake',
      description:
          'Decadent individual chocolate cakes with a warm, molten centre. Ready in under 30 minutes.',
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=800&q=80',
      cuisine: 'Continental',
      mealType: 'Dessert',
      difficulty: 'Medium',
      prepMinutes: 15,
      cookMinutes: 12,
      servings: 2,
      rating: 4.9,
      reviewCount: 540,
      calories: 450,
      dietTags: ['Vegetarian'],
      authorName: 'Chef Pierre',
      ingredients: [
        RecipeIngredient('Dark chocolate', 120, 'g'),
        RecipeIngredient('Butter', 100, 'g'),
        RecipeIngredient('Eggs', 2, 'whole'),
        RecipeIngredient('Sugar', 0.25, 'cup'),
        RecipeIngredient('Flour', 2, 'tbsp'),
      ],
      steps: [
        'Melt chocolate with butter until glossy.',
        'Whisk eggs with sugar until pale, then fold in chocolate.',
        'Sift in flour and combine gently.',
        'Pour into greased ramekins and bake at 200°C for 12 minutes.',
        'Turn out and serve immediately while molten.',
      ],
      nutrition: Nutrition(calories: 450, proteinG: 7, carbsG: 42, fatG: 29, fiberG: 3, sugarG: 32),
    ),
  ];

  static List<Recipe> get trending => [recipes[5], recipes[0], recipes[2]];
  static List<Recipe> get quickMeals =>
      recipes.where((r) => r.totalMinutes <= 30).toList();
  static List<Recipe> recommendedFor(String name) => recipes;
  static Recipe get recipeOfTheDay => recipes[0];

  /// Common ingredients for the "What's in your fridge?" picker.
  static const List<String> pantry = [
    'Chicken', 'Rice', 'Onion', 'Tomato', 'Garlic', 'Ginger', 'Eggs', 'Milk',
    'Butter', 'Flour', 'Cheese', 'Spinach', 'Potato', 'Carrot', 'Beef',
    'Pasta', 'Yogurt', 'Lemon', 'Chilli', 'Coconut milk', 'Tofu', 'Mushroom',
    'Bell pepper', 'Cream', 'Basil', 'Avocado', 'Beans', 'Corn', 'Honey', 'Sugar',
  ];

  static const List<Review> reviews = [
    Review(
      id: 'r1',
      author: 'Sara Ahmed',
      avatarColorSeed: 'S',
      rating: 5,
      text: 'Absolutely delicious! The spice balance was perfect and my family loved it. Will definitely make again.',
      timeAgo: '2 days ago',
      helpful: 24,
      photoUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&q=80',
    ),
    Review(
      id: 'r2',
      author: 'Bilal Khan',
      avatarColorSeed: 'B',
      rating: 4,
      text: 'Great recipe, though I added a bit more chilli. The instructions were really easy to follow.',
      timeAgo: '5 days ago',
      helpful: 11,
    ),
    Review(
      id: 'r3',
      author: 'Maria Lopez',
      avatarColorSeed: 'M',
      rating: 5,
      text: 'Restaurant quality at home. The servings adjuster made it easy to cook for a crowd.',
      timeAgo: '1 week ago',
      helpful: 8,
    ),
  ];

  static List<ShoppingItem> shoppingList() => [
        ShoppingItem(name: 'Basmati rice', quantity: '2 cups', aisle: 'Pantry'),
        ShoppingItem(name: 'Chicken', quantity: '500 g', aisle: 'Meat'),
        ShoppingItem(name: 'Onion', quantity: '2 large', aisle: 'Produce'),
        ShoppingItem(name: 'Tomato', quantity: '3 medium', aisle: 'Produce'),
        ShoppingItem(name: 'Spinach', quantity: '2 cups', aisle: 'Produce'),
        ShoppingItem(name: 'Yogurt', quantity: '1 cup', aisle: 'Dairy', checked: true),
        ShoppingItem(name: 'Parmesan', quantity: '100 g', aisle: 'Dairy'),
        ShoppingItem(name: 'Heavy cream', quantity: '250 ml', aisle: 'Dairy'),
        ShoppingItem(name: 'Penne pasta', quantity: '300 g', aisle: 'Pantry'),
        ShoppingItem(name: 'Biryani masala', quantity: '1 box', aisle: 'Pantry', checked: true),
        ShoppingItem(name: 'Burger buns', quantity: '6 pcs', aisle: 'Bakery'),
      ];

  static const List<NutritionEntry> nutritionLog = [
    NutritionEntry(title: 'Avocado Berry Bowl', meal: 'Breakfast', calories: 320, proteinG: 8, carbsG: 38, fatG: 16),
    NutritionEntry(title: 'Creamy Tuscan Pasta', meal: 'Lunch', calories: 620, proteinG: 19, carbsG: 72, fatG: 28),
    NutritionEntry(title: 'Chicken Biryani', meal: 'Dinner', calories: 540, proteinG: 32, carbsG: 58, fatG: 18),
  ];

  /// Calories consumed across the last 7 days (Mon..Sun) for the weekly chart.
  static const List<double> weeklyCalories = [1850, 2100, 1480, 1980, 1620, 2250, 1480];
}
