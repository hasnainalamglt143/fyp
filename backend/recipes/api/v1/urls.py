from django.urls import path
from . import views

urlpatterns = [
    path('ingredients/', views.IngredientsListAPIView.as_view(), name='api_v1_ingredients'),
    path('recipes/', views.RecipeListAPIView.as_view(), name='api_v1_recipes'),
    path('recipes/<int:recipe_id>/', views.RecipeDetailAPIView.as_view(), name='api_v1_recipe_detail'),
    path('recommend/', views.RecommendAPIView.as_view(), name='api_v1_recommend'),
]
