# Kitchen Key — Recipe Dataset

Recipes collected via an LLM (ChatGPT, driven by `../data_collection.py`).

## Files
- **`recipes.jsonl`** — primary store. One JSON recipe object per line (append-friendly, easy to resume).
- **`recipes.json`** — full consolidated array (rewritten on every save; convenient for import/inspection).
- **`recipe_schema.json`** — JSON Schema describing every field.
- **`missed_batches.csv`** — log of cuisines/batches that failed to parse, for retrying.

## Why this schema
Fields are chosen to match what the Kitchen Key app actually uses:
- **Search filters** → `cuisine`, `country`, `meal_type`, `difficulty`, `tags`, `diet_flags`, time fields.
- **Recipe detail + servings scaler** → structured `ingredients` (name/quantity/unit), `steps`, `servings`.
- **Shopping list grouping** → each ingredient's `aisle`.
- **Nutrition tracker** → `nutrition_per_serving` (grams, per serving).
- **Allergy feature** → `allergens`.
- **Halal/Haram feature** → `halal_haram_status` (Halal / Haram / Mashbooh) + `halal_haram_reason`.

## Important honesty notes
- `id`, `created_at`, `rating` (0), `review_count` (0), `author` are set **locally**, not by the LLM.
- `image_url` is left blank — an LLM cannot supply real photos. Use `image_query` in a later pass to fetch images from a stock/image API.
- `nutrition_per_serving` and `halal_haram_status` are **LLM estimates** (`nutrition_estimated: true`). Good for a prototype; verify before relying on them.
