from django.urls import path, include
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('api/v1/', include('recipes.api.v1.urls')),
    path('api/recommend/', views.get_recommendations, name='get_recommendations'),
    path('recipe/<int:recipe_id>/', views.recipe_detail, name='recipe_detail'),
]