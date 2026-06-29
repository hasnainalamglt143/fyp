from django.urls import path

from . import views

urlpatterns = [
    path("recipes/", views.RecipeListAPIView.as_view(), name="api_v1_recipes"),
    path("recipes/suggest/", views.SuggestByIngredientsAPIView.as_view(), name="api_v1_suggest"),
    path("recipes/<int:recipe_id>/", views.RecipeDetailAPIView.as_view(), name="api_v1_recipe_detail"),
    path("ingredients/", views.IngredientsAPIView.as_view(), name="api_v1_ingredients"),
    path("meta/", views.MetaAPIView.as_view(), name="api_v1_meta"),
]
