/// A user review on a recipe.
class Review {
  final String id;
  final String author;
  final String avatarColorSeed;
  final double rating;
  final String text;
  final String timeAgo;
  final int helpful;
  final String? photoUrl;

  const Review({
    required this.id,
    required this.author,
    required this.avatarColorSeed,
    required this.rating,
    required this.text,
    required this.timeAgo,
    this.helpful = 0,
    this.photoUrl,
  });
}
