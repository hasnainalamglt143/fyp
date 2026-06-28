import pickle
import json
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity
import os

import pickle
import json
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity
import os
from scipy.sparse import csr_matrix

DEFAULT_ARTIFACTS_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'ml_artifacts',
)


class RecipeRecommender:
    def __init__(self, artifacts_path=DEFAULT_ARTIFACTS_PATH):
        self.artifacts_path = artifacts_path
        self.load_artifacts()
    
    def load_artifacts(self):
        """Load all ML artifacts"""
        try:
            # Load TF-IDF vectorizer
            self.tfidf_vectorizer = pickle.load(
                open(f'{self.artifacts_path}/tfidf_vectorizer.pkl', 'rb')
            )
            
            # Load SVD transformer if saved (from your ML code)
            try:
                self.svd_text = pickle.load(
                    open(f'{self.artifacts_path}/svd_transformer.pkl', 'rb')
                )
                print("Loaded SVD transformer")
            except:
                print("SVD transformer not found, using direct features")
            
            # Load recipe features
            self.recipe_features = pickle.load(
                open(f'{self.artifacts_path}/recipe_text_features.pkl', 'rb')
            )
            
            # Load recipe metadata
            self.recipes_df = pd.read_pickle(
                f'{self.artifacts_path}/recipe_metadata.pkl'
            )
            print(f"Loaded {len(self.recipes_df)} recipes")
            
            # Load popular recipes
            self.popular_recipes = pd.read_pickle(
                f'{self.artifacts_path}/popular_recipes.pkl'
            )

            # Ensure popular recipes include required fields from metadata
            desired_cols = ['ingredients', 'tags', 'nutrition', 'image_url']
            extra_cols = [col for col in desired_cols
                          if col in self.recipes_df.columns
                          and col not in self.popular_recipes.columns]
            if extra_cols:
                self.popular_recipes = self.popular_recipes.merge(
                    self.recipes_df[['id'] + extra_cols],
                    on='id',
                    how='left'
                )
            
            # Load unique ingredients
            with open(f'{self.artifacts_path}/unique_ingredients.json', 'r') as f:
                self.unique_ingredients = json.load(f)
            
            print("[OK] ML artifacts loaded successfully")
            
        except Exception as e:
            print(f"[ERROR] Error loading artifacts: {e}")
            import traceback
            traceback.print_exc()
            raise
    
    def recommend_by_ingredients(self, ingredients_list, top_n=10):
        """Recommend recipes based on ingredients"""
        if not ingredients_list:
            return []
        
        # Create search query
        search_query = " ".join(ingredients_list)
        
        try:
            # Transform to TF-IDF vector (2000 dimensions)
            query_tfidf = self.tfidf_vectorizer.transform([search_query])
            
            print(f"TF-IDF query shape: {query_tfidf.shape}")
            print(f"Recipe features shape: {self.recipe_features.shape}")
            
            # Transform query using the same SVD as recipes
            if hasattr(self, 'svd_text'):
                query_vec = self.svd_text.transform(query_tfidf)
                print(f"After SVD query shape: {query_vec.shape}")
            else:
                # If SVD not saved, we need to handle it differently
                print("SVD transformer not found, checking for alternative...")
                
                # Check if we have the full TF-IDF matrix to transform query
                if hasattr(self, 'tfidf_matrix'):
                    # Transform query to match the recipe feature space
                    query_vec = query_tfidf.dot(self.tfidf_matrix.T)
                else:
                    print("Cannot transform query to match recipe space")
                    return self.get_popular_recipes(top_n)
            
            # Calculate similarities
            similarities = cosine_similarity(query_vec, self.recipe_features)[0]
            print(f"Similarities calculated. Min: {similarities.min():.4f}, Max: {similarities.max():.4f}")
            
            # Get top N indices
            top_indices = similarities.argsort()[-top_n:][::-1]
            
            # Filter by similarity threshold and get recipes
            results = []
            for idx in top_indices:
                if similarities[idx] > 0.01:  # Threshold
                    try:
                        recipe = self.recipes_df.iloc[idx].to_dict()
                        recipe['similarity_score'] = float(similarities[idx] * 100)  # As percentage
                        results.append(recipe)
                    except Exception as e:
                        print(f"Error getting recipe at index {idx}: {e}")
                        continue
            
            print(f"[OK] Found {len(results)} recipes")
            return results[:top_n]
            
        except Exception as e:
            print(f"[ERROR] Error in recommend_by_ingredients: {e}")
            import traceback
            traceback.print_exc()
            # Fallback to simple matching
            return self.recommend_by_ingredients_simple(ingredients_list, top_n)
        
    def get_popular_recipes(self, top_n=20, offset=0):
        """Get top popular recipes with optional offset"""
        try:
            limit = int(top_n)
        except (TypeError, ValueError):
            limit = 20

        try:
            offset = int(offset)
        except (TypeError, ValueError):
            offset = 0

        if limit <= 0:
            return []
        if offset < 0:
            offset = 0

        end = offset + limit
        return self.popular_recipes.iloc[offset:end].to_dict('records')

    def get_popular_recipes_count(self):
        """Get total count of popular recipes"""
        return int(len(self.popular_recipes))
    
    def get_unique_ingredients(self):
        """Get all unique ingredients for dropdown"""
        return self.unique_ingredients
    
    def get_recipe_by_id(self, recipe_id):
        """Get recipe details by ID"""
        try:
            recipe_id = int(recipe_id)
            recipe = self.recipes_df[self.recipes_df['id'] == recipe_id]
            if not recipe.empty:
                return recipe.iloc[0].to_dict()
            return None
        except:
            return None

# Create singleton instance
recommender = RecipeRecommender()
