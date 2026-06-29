from django.http import JsonResponse
from django.urls import include, path


def api_root(request):
    return JsonResponse({
        "service": "Kitchen Key API",
        "version": "v1",
        "endpoints": {
            "recipes": "/api/v1/recipes/?search=&cuisine=&meal_type=&difficulty=&diet=&halal=&max_minutes=&sort=&page=&limit=",
            "recipe_detail": "/api/v1/recipes/<id>/",
            "suggest_by_ingredients": "POST /api/v1/recipes/suggest/  body: {\"ingredients\": [\"chicken\", \"rice\"]}",
            "ingredients": "/api/v1/ingredients/",
            "meta": "/api/v1/meta/",
            "docs": "/swagger/",
        },
    })


urlpatterns = [
    path("", api_root, name="home"),
    path("api/v1/", include("recipes.api.v1.urls")),
]
