from rest_framework import serializers


class RecipeSummarySerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    minutes = serializers.IntegerField()
    ingredients = serializers.CharField()
    similarity_score = serializers.FloatField(required=False)
    nutrition = serializers.ListField(child=serializers.CharField(), required=False)
    nutrition_info = serializers.DictField(child=serializers.CharField(), required=False)
    image_url = serializers.CharField(allow_blank=True, required=False)
    tags = serializers.CharField(allow_blank=True, required=False)


class RecipeDetailSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField(allow_blank=True)
    minutes = serializers.IntegerField()
    ingredients_list = serializers.ListField(child=serializers.CharField())
    steps_list = serializers.ListField(child=serializers.CharField())
    tags_list = serializers.ListField(child=serializers.CharField())
    nutrition = serializers.ListField(child=serializers.CharField())
    nutrition_info = serializers.DictField(child=serializers.CharField(), required=False)
    image_url = serializers.CharField(allow_blank=True, required=False)


class RecipeRecommendSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField(allow_blank=True)
    minutes = serializers.IntegerField()
    ingredients = serializers.CharField()
    ingredients_list = serializers.ListField(child=serializers.CharField(), required=False)
    steps_list = serializers.ListField(child=serializers.CharField(), required=False)
    tags = serializers.CharField(allow_blank=True, required=False)
    tags_list = serializers.ListField(child=serializers.CharField(), required=False)
    similarity_score = serializers.FloatField(required=False)
    nutrition = serializers.ListField(child=serializers.CharField(), required=False)
    nutrition_info = serializers.DictField(child=serializers.CharField(), required=False)
    image_url = serializers.CharField(allow_blank=True, required=False)


class IngredientsListSerializer(serializers.Serializer):
    ingredients = serializers.ListField(child=serializers.CharField())


class RecommendRequestSerializer(serializers.Serializer):
    ingredients = serializers.ListField(child=serializers.CharField(), allow_empty=False)
