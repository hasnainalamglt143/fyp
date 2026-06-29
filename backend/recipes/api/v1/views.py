"""DRF API (v1) serving the new LLM-collected recipe dataset."""

from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from recipes.data_store import store


def _coerce_int(value, default=None):
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _summary(recipe):
    """Trimmed card representation for list/suggestion responses."""
    nut = recipe.get("nutrition_per_serving") or {}
    data = {
        "id": recipe.get("id"),
        "name": recipe.get("name"),
        "description": recipe.get("description", ""),
        "cuisine": recipe.get("cuisine", ""),
        "country": recipe.get("country", ""),
        "meal_type": recipe.get("meal_type", ""),
        "difficulty": recipe.get("difficulty", ""),
        "total_time_minutes": recipe.get("total_time_minutes", 0),
        "servings": recipe.get("servings", 0),
        "calories": nut.get("calories", 0),
        "halal_haram_status": recipe.get("halal_haram_status", ""),
        "diet_flags": recipe.get("diet_flags", []),
        "tags": recipe.get("tags", []),
        "rating": recipe.get("rating", 0),
        "review_count": recipe.get("review_count", 0),
        "image_url": recipe.get("image_url", ""),
        "image_query": recipe.get("image_query", ""),
    }
    # Carry suggestion scores when present.
    for extra in ("match_score", "matched_count", "total_ingredients"):
        if extra in recipe:
            data[extra] = recipe[extra]
    return data


def _paginate(request, items):
    page = _coerce_int(request.query_params.get("page"), 1) or 1
    limit = _coerce_int(request.query_params.get("limit"), 20) or 20
    limit = max(1, min(limit, 100))
    total = len(items)
    start = (page - 1) * limit
    end = start + limit
    num_pages = (total + limit - 1) // limit
    return {
        "count": total,
        "page": page,
        "num_pages": num_pages,
        "next": page < num_pages,
        "results": items[start:end],
    }


class RecipeListAPIView(APIView):
    """GET /api/v1/recipes/ — search + filter + sort + paginate."""
    permission_classes = [AllowAny]

    def get(self, request):
        items = store.query(
            search=request.query_params.get("search", "").strip(),
            cuisine=request.query_params.get("cuisine", "").strip(),
            meal_type=request.query_params.get("meal_type", "").strip(),
            difficulty=request.query_params.get("difficulty", "").strip(),
            diet=request.query_params.get("diet", "").strip(),
            halal=request.query_params.get("halal", "").strip(),
            country=request.query_params.get("country", "").strip(),
            max_minutes=_coerce_int(request.query_params.get("max_minutes")),
            sort=request.query_params.get("sort", "name").strip() or "name",
        )
        payload = _paginate(request, [_summary(r) for r in items])
        return Response(payload)


class RecipeDetailAPIView(APIView):
    """GET /api/v1/recipes/<id>/ — full recipe."""
    permission_classes = [AllowAny]

    def get(self, request, recipe_id):
        recipe = store.get(recipe_id)
        if not recipe:
            return Response({"detail": "Recipe not found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(recipe)


class SuggestByIngredientsAPIView(APIView):
    """POST /api/v1/recipes/suggest/  body: {"ingredients": ["chicken", "rice"]}

    Returns recipes ranked by how many of their ingredients you already have.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        ingredients = request.data.get("ingredients", [])
        # Be tolerant of form-encoded bodies and comma-separated strings.
        if not isinstance(ingredients, list) and hasattr(request.data, "getlist"):
            ingredients = request.data.getlist("ingredients")
        if isinstance(ingredients, str):
            ingredients = [s.strip() for s in ingredients.split(",") if s.strip()]
        ingredients = [str(i).strip() for i in ingredients if str(i).strip()]
        if not ingredients:
            return Response({"detail": "Provide a non-empty 'ingredients' list."},
                            status=status.HTTP_400_BAD_REQUEST)
        top_n = _coerce_int(request.query_params.get("limit"), 20) or 20
        matches = store.suggest_by_ingredients(ingredients, top_n=top_n)
        return Response({
            "count": len(matches),
            "ingredients": ingredients,
            "results": [_summary(r) for r in matches],
        })


class IngredientsAPIView(APIView):
    """GET /api/v1/ingredients/ — vocabulary for the 'what's in your fridge' picker."""
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({"ingredients": store.ingredient_vocabulary()})


class MetaAPIView(APIView):
    """GET /api/v1/meta/ — filter options (cuisines, meal types, diets, …)."""
    permission_classes = [AllowAny]

    def get(self, request):
        return Response(store.meta())
