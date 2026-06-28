from django.db import models

# Create your models here.
from django.db import models
import json

class Recipe(models.Model):
    recipe_id = models.IntegerField(unique=True)
    name = models.CharField(max_length=500)
    description = models.TextField(blank=True)
    minutes = models.IntegerField(default=0)
    ingredients = models.TextField()  # Store as JSON string
    steps = models.TextField()  # Store as JSON string
    tags = models.TextField(blank=True)  # Store as JSON string
    nutrition = models.TextField()  # Store as JSON string
    image_url = models.URLField(max_length=500, blank=True)
    
    @property
    def ingredients_list(self):
        return json.loads(self.ingredients) if self.ingredients else []
    
    @property
    def steps_list(self):
        return json.loads(self.steps) if self.steps else []
    
    @property
    def nutrition_list(self):
        return json.loads(self.nutrition) if self.nutrition else []
    
    @property
    def nutrition_info(self):
        """Return formatted nutrition info"""
        nutrition = self.nutrition_list
        if len(nutrition) >= 7:
            return {
                'calories': nutrition[0],
                'total_fat': nutrition[1],
                'sugar': nutrition[2],
                'sodium': nutrition[3],
                'protein': nutrition[4],
                'saturated_fat': nutrition[5],
                'carbohydrates': nutrition[6]
            }
        return {}
    
    @property
    def cooking_time(self):
        if self.minutes < 60:
            return f"{self.minutes} min"
        else:
            hours = self.minutes // 60
            mins = self.minutes % 60
            return f"{hours}h {mins}m" if mins else f"{hours}h"
    
    def __str__(self):
        return self.name
    
    class Meta:
        ordering = ['name']