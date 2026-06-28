# recipes/management/commands/import_recipes.py
import os
import pandas as pd
import json
from django.core.management.base import BaseCommand
from recipes.models import Recipe

class Command(BaseCommand):
    help = 'Import recipes from ML artifacts to Django database'
    
    def handle(self, *args, **kwargs):
        # Load recipe metadata
        recipes_df = pd.read_pickle('C:/Users/Muhammad Hasnain/Desktop/Recepies_recommender/recipes/ml_artifacts/recipe_metadata.pkl')
        
        # Import to database
        for _, row in recipes_df.iterrows():
            Recipe.objects.update_or_create(
                recipe_id=row['id'],
                defaults={
                    'name': row['name'][:500] if isinstance(row['name'], str) else 'Unknown',
                    'description': row['description'][:2000] if isinstance(row['description'], str) else '',
                    'minutes': int(row['minutes']) if pd.notnull(row['minutes']) else 0,
                    'ingredients': row['ingredients'] if isinstance(row['ingredients'], str) else json.dumps([]),
                    'steps': row['steps'] if isinstance(row['steps'], str) else json.dumps([]),
                    'tags': row['tags'] if isinstance(row['tags'], str) else json.dumps([]),
                    'nutrition': row['nutrition'] if isinstance(row['nutrition'], str) else json.dumps([]),
                    'image_url': row.get('image_url', ''),
                }
            )
        
        self.stdout.write(self.style.SUCCESS(
            f'Successfully imported {len(recipes_df)} recipes'
        ))