"""
In-memory store for the new LLM-collected recipe dataset (data/recipes.json).

Replaces the old Food.com pickle/ML pipeline. Loads the JSON once, reloads
automatically when the file changes, and provides search / filter / detail /
ingredient-suggestion / metadata operations used by the API.
"""

import json
import os
import re
import threading

# backend/recipes/data_store.py -> backend/data/recipes.json
_BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JSON_PATH = os.path.join(_BASE, "data", "recipes.json")
JSONL_PATH = os.path.join(_BASE, "data", "recipes.jsonl")

# Words to ignore when tokenising ingredient names for matching.
_STOP = {
    "and", "or", "the", "for", "with", "to", "taste", "optional", "fresh",
    "chopped", "sliced", "diced", "minced", "ground", "large", "small", "medium",
    "cup", "cups", "tbsp", "tsp", "tablespoon", "teaspoon", "gram", "grams",
    "kg", "ml", "litre", "liter", "oz", "lb", "pcs", "pieces", "piece", "pinch",
    "cloves", "clove", "bunch", "can", "cans", "into", "cut", "boneless", "bone",
    "skinless", "powder", "paste", "whole", "half", "ripe", "raw", "dried",
}


def _food_tokens(text):
    """Key food words from an ingredient name (drops units/quantities/adjectives)."""
    words = re.findall(r"[a-zA-Z]+", str(text).lower())
    return {w for w in words if len(w) > 2 and w not in _STOP}


def _calories(recipe):
    nut = recipe.get("nutrition_per_serving") or {}
    try:
        return int(float(nut.get("calories", 0)))
    except (TypeError, ValueError):
        return 0


class RecipeStore:
    def __init__(self):
        self._recipes = []
        self._by_id = {}
        self._mtime = 0
        self._lock = threading.Lock()
        self._ensure_loaded()

    # ---- loading ----
    def _load(self):
        recipes = []
        if os.path.exists(JSON_PATH):
            try:
                with open(JSON_PATH, "r", encoding="utf-8") as f:
                    recipes = json.load(f)
            except (json.JSONDecodeError, OSError):
                recipes = []
        elif os.path.exists(JSONL_PATH):
            with open(JSONL_PATH, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line:
                        try:
                            recipes.append(json.loads(line))
                        except json.JSONDecodeError:
                            continue
        self._recipes = [r for r in recipes if isinstance(r, dict) and r.get("id") is not None]
        self._by_id = {int(r["id"]): r for r in self._recipes}

    def _ensure_loaded(self):
        path = JSON_PATH if os.path.exists(JSON_PATH) else JSONL_PATH
        try:
            mtime = os.path.getmtime(path) if os.path.exists(path) else 0
        except OSError:
            mtime = 0
        if mtime != self._mtime:
            with self._lock:
                if mtime != self._mtime:
                    self._load()
                    self._mtime = mtime

    # ---- reads ----
    def all(self):
        self._ensure_loaded()
        return self._recipes

    def get(self, recipe_id):
        self._ensure_loaded()
        try:
            return self._by_id.get(int(recipe_id))
        except (TypeError, ValueError):
            return None

    def query(self, search="", cuisine="", meal_type="", difficulty="",
              diet="", halal="", country="", max_minutes=None, sort="name"):
        items = list(self.all())

        if search:
            s = search.lower()
            def matches(r):
                if s in str(r.get("name", "")).lower():
                    return True
                if s in str(r.get("description", "")).lower():
                    return True
                if any(s in str(t).lower() for t in r.get("tags", [])):
                    return True
                if any(s in str(i.get("name", "")).lower() for i in r.get("ingredients", [])):
                    return True
                return False
            items = [r for r in items if matches(r)]

        def eq(field, value):
            return [r for r in items if str(r.get(field, "")).lower() == value.lower()]

        if cuisine and cuisine.lower() != "all":
            items = eq("cuisine", cuisine)
        if meal_type:
            items = [r for r in items if str(r.get("meal_type", "")).lower() == meal_type.lower()]
        if difficulty:
            items = [r for r in items if str(r.get("difficulty", "")).lower() == difficulty.lower()]
        if country:
            items = [r for r in items if str(r.get("country", "")).lower() == country.lower()]
        if halal:
            items = [r for r in items if str(r.get("halal_haram_status", "")).lower() == halal.lower()]
        if diet:
            items = [r for r in items
                     if any(diet.lower() == str(d).lower() for d in r.get("diet_flags", []))]
        if max_minutes is not None:
            items = [r for r in items if (r.get("total_time_minutes") or 0) <= max_minutes]

        reverse = sort.startswith("-")
        key = sort.lstrip("-")
        if key in ("calories",):
            items.sort(key=_calories, reverse=reverse)
        elif key in ("total_time_minutes", "rating", "review_count"):
            items.sort(key=lambda r: r.get(key) or 0, reverse=reverse)
        else:
            items.sort(key=lambda r: str(r.get("name", "")).lower(), reverse=reverse)
        return items

    def suggest_by_ingredients(self, ingredients, top_n=20):
        """Rank recipes by how many of their ingredients the user has."""
        user_tokens = set()
        for ing in ingredients:
            user_tokens |= _food_tokens(ing)
        if not user_tokens:
            return []

        scored = []
        for r in self.all():
            ing_sets = [_food_tokens(i.get("name", "")) for i in r.get("ingredients", [])]
            ing_sets = [s for s in ing_sets if s]
            if not ing_sets:
                continue
            covered = sum(1 for s in ing_sets if s & user_tokens)
            if covered == 0:
                continue
            coverage = covered / len(ing_sets)
            scored.append((coverage, covered, r))

        scored.sort(key=lambda x: (x[0], x[1]), reverse=True)
        results = []
        for coverage, covered, r in scored[:top_n]:
            item = dict(r)
            item["match_score"] = round(coverage * 100)
            item["matched_count"] = covered
            item["total_ingredients"] = len(r.get("ingredients", []))
            results.append(item)
        return results

    def ingredient_vocabulary(self, limit=200):
        """Clean, frequency-ranked ingredient words for the 'fridge' picker."""
        freq = {}
        for r in self.all():
            for ing in r.get("ingredients", []):
                for tok in _food_tokens(ing.get("name", "")):
                    freq[tok] = freq.get(tok, 0) + 1
        ranked = sorted(freq.items(), key=lambda kv: kv[1], reverse=True)
        return [tok.title() for tok, _ in ranked[:limit]]

    def meta(self):
        recipes = self.all()
        diet = set()
        for r in recipes:
            diet.update(r.get("diet_flags", []))
        return {
            "count": len(recipes),
            "cuisines": sorted({r.get("cuisine") for r in recipes if r.get("cuisine")}),
            "countries": sorted({r.get("country") for r in recipes if r.get("country")}),
            "meal_types": sorted({r.get("meal_type") for r in recipes if r.get("meal_type")}),
            "difficulties": sorted({r.get("difficulty") for r in recipes if r.get("difficulty")}),
            "diet_flags": sorted(diet),
        }


# Singleton used by the API views.
store = RecipeStore()
