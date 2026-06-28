import ast
import json
from rest_framework import status
from rest_framework.generics import GenericAPIView
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

from recipes.ml_utils.recommender import recommender
from recipes.utils import clean_recipe_steps
from .serializers import (
    IngredientsListSerializer,
    RecipeDetailSerializer,
    RecipeSummarySerializer,
    RecipeRecommendSerializer,
    RecommendRequestSerializer,
)


def _parse_list(value):
    if isinstance(value, list):
        return value
    if not value:
        return []
    if isinstance(value, str):
        stripped = value.strip()
        if stripped.startswith('[') and stripped.endswith(']'):
            try:
                return json.loads(stripped)
            except json.JSONDecodeError:
                try:
                    parsed = ast.literal_eval(stripped)
                    return parsed if isinstance(parsed, list) else []
                except (ValueError, SyntaxError):
                    return []
        if ',' in stripped:
            return [item.strip() for item in stripped.split(',') if item.strip()]
    return []


def _parse_steps(value):
    steps = _parse_list(value)
    return clean_recipe_steps(steps)


def _parse_nutrition(value):
    if isinstance(value, list):
        return value
    if not value:
        return []
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return []
    return []


_NUTRITION_KEYS = (
    'calories',
    'total_fat',
    'sugar',
    'sodium',
    'protein',
    'saturated_fat',
    'carbohydrates',
)


def _nutrition_info(values):
    if not values:
        return {}
    info = {}
    for idx, key in enumerate(_NUTRITION_KEYS):
        if idx < len(values):
            info[key] = values[idx]
    return info


def _clean_image_url(value):
    if value is None:
        return ''
    if isinstance(value, float) and value != value:
        return ''
    if isinstance(value, str):
        return value.strip()
    return str(value).strip()


def _absolute_image_url(request, value):
    url = _clean_image_url(value)
    if not url:
        return ''
    if url.startswith('http://') or url.startswith('https://'):
        return url
    return request.build_absolute_uri(url)


def _listish_to_lower_set(value):
    if isinstance(value, list):
        return {str(item).lower() for item in value}
    if isinstance(value, str):
        parsed = _parse_list(value)
        if parsed:
            return {str(item).lower() for item in parsed}
        return {value.lower()}
    return set()


def _stringify_listish(value):
    if isinstance(value, list):
        return ', '.join(str(item) for item in value)
    if isinstance(value, str):
        parsed = _parse_list(value)
        if parsed:
            return ', '.join(str(item) for item in parsed)
        return value
    return ''


def _coerce_int(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


class IngredientsListAPIView(GenericAPIView):
    queryset = []
    serializer_class = IngredientsListSerializer

    def get(self, request):
        ingredients = recommender.get_unique_ingredients()
        return Response({'ingredients': ingredients})


class RecipeListPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'limit'
    page_query_param = 'page'


class RecipeListAPIView(GenericAPIView):
    pagination_class = RecipeListPagination
    queryset = []
    serializer_class = RecipeSummarySerializer

    def get(self, request):
        recipes_df = recommender.recipes_df
        filtered = recipes_df

        search = request.query_params.get('search', '').strip()
        if search:
            name_series = filtered['name'].fillna('').astype(str)
            desc_series = filtered['description'].fillna('').astype(str)
            filtered = filtered[
                name_series.str.contains(search, case=False, na=False)
                | desc_series.str.contains(search, case=False, na=False)
            ]

        name_filter = request.query_params.get('name', '').strip()
        if name_filter:
            name_series = filtered['name'].fillna('').astype(str)
            filtered = filtered[
                name_series.str.contains(name_filter, case=False, na=False)
            ]

        tags_param = request.query_params.get('tags', '')
        tag_terms = [term.lower() for term in _parse_list(tags_param)]
        if tag_terms and 'tags' in filtered.columns:
            filtered = filtered[
                filtered['tags'].apply(
                    lambda value: bool(_listish_to_lower_set(value) & set(tag_terms))
                )
            ]

        min_minutes = _coerce_int(request.query_params.get('min_minutes'))
        if min_minutes is not None and 'minutes' in filtered.columns:
            filtered = filtered[
                filtered['minutes'].apply(lambda value: (_coerce_int(value) or 0) >= min_minutes)
            ]

        max_minutes = _coerce_int(request.query_params.get('max_minutes'))
        if max_minutes is not None and 'minutes' in filtered.columns:
            filtered = filtered[
                filtered['minutes'].apply(lambda value: (_coerce_int(value) or 0) <= max_minutes)
            ]

        if 'name' in filtered.columns:
            filtered = filtered.sort_values(by='name', kind='mergesort', na_position='last')

        records = filtered.to_dict('records')
        page = self.paginate_queryset(records)
        page_items = page if page is not None else records

        formatted = []
        for recipe in page_items:
            nutrition = _parse_nutrition(recipe.get('nutrition'))
            formatted.append({
                'id': recipe.get('id'),
                'name': recipe.get('name'),
                'description': (recipe.get('description', '')[:150] + '...') if recipe.get('description') else '',
                'minutes': recipe.get('minutes', 0),
                'ingredients': _stringify_listish(recipe.get('ingredients', '')),
                'nutrition': nutrition[:7] if nutrition else [],
                'nutrition_info': _nutrition_info(nutrition[:7] if nutrition else []),
                'image_url': _absolute_image_url(request, recipe.get('image_url', '')),
                'tags': _stringify_listish(recipe.get('tags', '')),
            })

        serializer = RecipeSummarySerializer(formatted, many=True)
        if page is not None:
            return self.get_paginated_response(serializer.data)
        return Response({'results': serializer.data, 'count': len(serializer.data)})


class RecipeDetailAPIView(GenericAPIView):
    queryset = []
    serializer_class = RecipeDetailSerializer

    def get(self, request, recipe_id):
        recipe = recommender.get_recipe_by_id(int(recipe_id))
        if not recipe:
            return Response({'detail': 'Recipe not found'}, status=status.HTTP_404_NOT_FOUND)

        data = {
            'id': recipe.get('id'),
            'name': recipe.get('name'),
            'description': recipe.get('description', ''),
            'minutes': recipe.get('minutes', 0),
            'ingredients_list': _parse_list(recipe.get('ingredients', '')),
            'steps_list': _parse_steps(recipe.get('steps', '')),
            'tags_list': _parse_list(recipe.get('tags', '')),
            'nutrition': _parse_nutrition(recipe.get('nutrition'))[:7],
            'nutrition_info': _nutrition_info(_parse_nutrition(recipe.get('nutrition'))[:7]),
            'image_url': _absolute_image_url(request, recipe.get('image_url', '')),
        }

        serializer = RecipeDetailSerializer(data)
        return Response(serializer.data)


class RecommendAPIView(GenericAPIView):
    queryset = []
    serializer_class = RecommendRequestSerializer

    def post(self, request):
        ingredients = request.data.get('ingredients', [])
        if not ingredients:
            return Response({'error': 'No ingredients selected'}, status=status.HTTP_400_BAD_REQUEST)

        recommendations = recommender.recommend_by_ingredients(ingredients, top_n=15)
        formatted = []
        for recipe in recommendations:
            nutrition = _parse_nutrition(recipe.get('nutrition'))
            ingredients_list = _parse_list(recipe.get('ingredients', ''))
            steps_list = _parse_steps(recipe.get('steps', ''))
            tags_list = _parse_list(recipe.get('tags', ''))
            formatted.append({
                'id': recipe.get('id'),
                'name': recipe.get('name'),
                'description': (recipe.get('description', '')[:150] + '...') if recipe.get('description') else '',
                'minutes': recipe.get('minutes', 0),
                'ingredients': _stringify_listish(recipe.get('ingredients', '')),
                'ingredients_list': ingredients_list,
                'steps_list': steps_list,
                'similarity_score': round(recipe.get('similarity_score', 0), 1),
                'nutrition': nutrition[:7] if nutrition else [],
                'nutrition_info': _nutrition_info(nutrition[:7] if nutrition else []),
                'image_url': _absolute_image_url(request, recipe.get('image_url', '')),
                'tags': _stringify_listish(recipe.get('tags', '')),
                'tags_list': tags_list,
            })

        serializer = RecipeRecommendSerializer(formatted, many=True)
        return Response({'success': True, 'results': serializer.data, 'count': len(serializer.data)})
