from django.shortcuts import render, redirect
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
import json
from .ml_utils.recommender import recommender

def home(request):
    """Homepage with popular recipes and ingredient selector"""
    # Get popular recipes
    popular_recipes = recommender.get_popular_recipes(top_n=12)
    
    # Get unique ingredients for dropdown
    ingredients = recommender.get_unique_ingredients()
    
    context = {
        'popular_recipes': popular_recipes,
        'ingredients_list':ingredients,  # First 100 for performance
        'total_recipes': len(recommender.recipes_df),
    }
    return render(request, 'recipes/home.html', context)


# In recipes/views.py, update the get_recommendations function:

@require_http_methods(["POST"])
def get_recommendations(request):
    """AJAX endpoint for ingredient-based recommendations"""
    try:
        data = json.loads(request.body)
        ingredients = data.get('ingredients', [])
        
        print(f"📦 Received ingredients: {ingredients}")
        
        if not ingredients:
            return JsonResponse({'error': 'No ingredients selected'}, status=400)
        
        # Get recommendations
        recommendations = recommender.recommend_by_ingredients(
            ingredients, top_n=15
        )
        
        print(f"📊 Found {len(recommendations)} recommendations")
        
        # Format response
        formatted_results = []
        for recipe in recommendations:
            # Parse nutrition if it's a string
            nutrition = recipe.get('nutrition')
            if isinstance(nutrition, str):
                try:
                    nutrition = json.loads(nutrition)
                except:
                    nutrition = []
            
            formatted_results.append({
                'id': recipe.get('id'),
                'name': recipe.get('name'),
                'description': recipe.get('description', '')[:150] + '...',
                'minutes': recipe.get('minutes', 0),
                'ingredients': recipe.get('ingredients', ''),
                'similarity_score': round(recipe.get('similarity_score', 0), 1),
                'nutrition': nutrition[:7] if nutrition else [],
                'image_url': recipe.get('image_url', ''),
                'tags': recipe.get('tags', ''),
            })
        
        return JsonResponse({
            'success': True,
            'results': formatted_results,
            'count': len(formatted_results)
        })
        
    except Exception as e:
        print(f"[ERROR] Error in get_recommendations: {e}")
        import traceback
        traceback.print_exc()
        return JsonResponse({'error': str(e)}, status=500)



from .utils import clean_recipe_steps

def recipe_detail(request, recipe_id):
    """Recipe detail page"""
    recipe = recommender.get_recipe_by_id(int(recipe_id))
    
    if not recipe:
        return render(request, 'recipes/404.html', status=404)
    
    # Parse nutrition - handle different formats
    nutrition = recipe.get('nutrition')
    if isinstance(nutrition, str):
        try:
            if nutrition.strip().startswith('[') and nutrition.strip().endswith(']'):
                nutrition = json.loads(nutrition)
            else:
                # Try to parse as list if it's malformed
                nutrition = eval(nutrition) if nutrition else []
        except (json.JSONDecodeError, SyntaxError):
            nutrition = []
    
    ingredients_raw = recipe.get('ingredients', '')
    ingredients_list = []
    
    if isinstance(ingredients_raw, str):
        try:
            if ingredients_raw.strip().startswith('[') and ingredients_raw.strip().endswith(']'):
                ingredients_list = json.loads(ingredients_raw)
            elif ',' in ingredients_raw:
                # If it's a comma-separated string
                ingredients_list = [ing.strip() for ing in ingredients_raw.split(',')]
            else:
                # Try eval for list representation
                ingredients_list = eval(ingredients_raw) if ingredients_raw else []
        except (json.JSONDecodeError, SyntaxError, ValueError):
            # If all else fails, split by common delimiters
            if ingredients_raw:
                # Try to clean and split
                cleaned = ingredients_raw.replace('[', '').replace(']', '').replace("'", "")
                ingredients_list = [ing.strip() for ing in cleaned.split(',') if ing.strip()]
            else:
                ingredients_list = []
    elif isinstance(ingredients_raw, list):
        ingredients_list = ingredients_raw
    else:
        ingredients_list = []
    
    # Parse steps - handle different formats
    steps_raw = recipe.get('steps', '')
    steps_list = []
    
    if isinstance(steps_raw, str):
        try:
            if steps_raw.strip().startswith('[') and steps_raw.strip().endswith(']'):
                steps_list = json.loads(steps_raw)
            else:
                steps_list = eval(steps_raw) if steps_raw else []
        except (json.JSONDecodeError, SyntaxError, ValueError):
            # If it's a single step or malformed
            if steps_raw:
                steps_list = [steps_raw]
            else:
                steps_list = []
    elif isinstance(steps_raw, list):
        steps_list = steps_raw
    else:
        steps_list = []
    
    steps_list=clean_recipe_steps(steps_list)
    print(type(steps_list))
    tags_raw = recipe.get('tags', '')
    tags_list = []
    
    if isinstance(tags_raw, str):
        try:
            if tags_raw.strip().startswith('[') and tags_raw.strip().endswith(']'):
                tags_list = json.loads(tags_raw)
            else:
                tags_list = eval(tags_raw) if tags_raw else []
        except (json.JSONDecodeError, SyntaxError, ValueError):
            if tags_raw:
                tags_list = [tag.strip() for tag in tags_raw.split(',') if tag.strip()]
            else:
                tags_list = []
    elif isinstance(tags_raw, list):
        tags_list = tags_raw
    print(steps_list)
    context = {
        'recipe': recipe,
        'nutrition': nutrition[:7] if nutrition else [],
        'ingredients_list': ingredients_list,
        'steps_list': steps_list,
        'tags_list': tags_list,
    }
    return render(request, 'recipes/recipe_detail.html', context)