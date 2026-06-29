"""
Kitchen Key — Recipe data collector.

Drives an existing, logged-in ChatGPT browser tab (via Chrome remote-debugging)
to generate structured recipe records and saves them into ./data/.

How it works (same mechanism as before):
1. Launch Chrome with --remote-debugging-port and your profile.
2. Log in to ChatGPT and open a chat in that window.
3. Run this script; it attaches to that tab, sends recipe-generation prompts
   batch-by-batch (by cuisine), parses the JSON, validates + de-duplicates,
   and appends to data/recipes.jsonl (+ rewrites data/recipes.json).

Output schema is documented in data/recipe_schema.json.
"""

import json
import logging
import os
import random
import re
import subprocess
import time
from datetime import datetime, timezone

import pandas as pd
from selenium import webdriver
from selenium.common.exceptions import StaleElementReferenceException, TimeoutException
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

# ---------------------------------------------------------------------------
# CONFIG  — edit these for your machine
# ---------------------------------------------------------------------------
CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
REMOTE_DEBUGGING_PORT = "9222"
# Use a Chrome profile that is already logged in to ChatGPT:
USER_DATA_DIR = r"C:\Users\EXARTH\AppData\Local\Google\Chrome\User Data\Profile 1"

# We collect ONE recipe per prompt (best schema compliance) and exclude
# already-collected dish names so the model keeps producing new dishes.
CUISINES = [
    "Pakistani", "Indian", "Italian", "Chinese", "Thai", "Mexican",
    "Turkish", "Middle Eastern", "Japanese", "Mediterranean",
    "American", "Afghan", "Continental", "Korean", "Lebanese",
    "Bangladeshi", "Greek", "Spanish", "French", "Vietnamese",
]
TARGET_PER_CUISINE = 60       # raise for more data (one prompt each — takes time)
MAX_ATTEMPTS_PER_RECIPE = 3   # retries to get a complete/valid recipe
MAX_CONSEC_FAILS = 4          # give up on a cuisine after this many failures in a row
EXCLUDE_CAP = 80              # max dish names to list in the exclude block (prompt size)
SAVE_EVERY = 5                # rewrite consolidated recipes.json every N saves

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
os.makedirs(DATA_DIR, exist_ok=True)
JSONL_PATH = os.path.join(DATA_DIR, "recipes.jsonl")
JSON_PATH = os.path.join(DATA_DIR, "recipes.json")
MISSED_PATH = os.path.join(DATA_DIR, "missed_batches.csv")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

# ---------------------------------------------------------------------------
# Allowed enum values (used for validation/normalisation)
# ---------------------------------------------------------------------------
MEAL_TYPES = {"Breakfast", "Lunch", "Dinner", "Snack", "Dessert", "Drinks"}
DIFFICULTIES = {"Easy", "Medium", "Hard"}
HALAL_STATUS = {"Halal", "Haram", "Mashbooh"}
AISLES = {"Produce", "Dairy", "Meat", "Seafood", "Pantry", "Bakery", "Frozen", "Spices", "Other"}
DIET_FLAGS = {"Vegetarian", "Vegan", "Gluten-Free", "Keto", "High-Protein", "Low-Carb", "Dairy-Free"}
ALLERGENS = {"Peanuts", "Tree Nuts", "Dairy", "Gluten", "Shellfish", "Fish", "Eggs", "Soy", "Sesame"}


# ---------------------------------------------------------------------------
# Prompt building
# ---------------------------------------------------------------------------
# One fully-populated example object so the model copies the exact JSON shape.
_EXAMPLE_ONE = """{
  "name": "Chicken Biryani",
  "description": "Fragrant basmati rice layered with spiced chicken and caramelised onions.",
  "cuisine": "Pakistani",
  "country": "Pakistan",
  "region": "Sindh",
  "meal_type": "Dinner",
  "course": "Main",
  "difficulty": "Medium",
  "prep_time_minutes": 30,
  "cook_time_minutes": 45,
  "servings": 4,
  "ingredients": [
    {"name": "basmati rice", "quantity": 2, "unit": "cups", "aisle": "Pantry", "notes": "soaked 30 min"},
    {"name": "chicken", "quantity": 500, "unit": "g", "aisle": "Meat", "notes": ""}
  ],
  "steps": ["Marinate the chicken in yogurt and spices.", "Par-boil the rice, then layer and steam."],
  "tags": ["rice", "spicy", "festive"],
  "diet_flags": ["High-Protein"],
  "allergens": ["Dairy"],
  "halal_haram_status": "Halal",
  "halal_haram_reason": "Uses halal chicken and contains no pork or alcohol.",
  "nutrition_per_serving": {"calories": 540, "protein_g": 32, "carbs_g": 58, "fat_g": 18, "fiber_g": 4, "sugar_g": 6, "sodium_mg": 720, "saturated_fat_g": 5},
  "image_query": "chicken biryani"
}"""

REFORMAT_PROMPT = (
    "Your previous reply was not valid JSON. Resend the SAME recipe as ONLY one raw JSON object "
    "inside a single ```json code block. No prose, no titles, no emojis, no headings. "
    "Start with { and end with }."
)

FIELD_FIX_SINGLE = (
    "That recipe was missing or had empty required fields. Resend the SAME dish as ONE JSON object "
    "with EVERY field filled and non-empty: name (not empty), description, cuisine, country, "
    "meal_type, difficulty, prep_time_minutes (integer), cook_time_minutes (integer), servings, "
    "ingredients (FLAT array of objects each with name/quantity/unit/aisle), steps, tags, diet_flags, "
    "allergens, halal_haram_status, halal_haram_reason, and nutrition_per_serving with numeric "
    "calories/protein_g/carbs_g/fat_g/fiber_g/sugar_g/sodium_mg/saturated_fat_g. "
    "One ```json code block, JSON object only, no prose."
)


def build_single_prompt(cuisine, exclude_names):
    """Prompt for ONE new recipe, excluding already-collected dish names."""
    exclude_block = ""
    if exclude_names:
        sample = exclude_names[-EXCLUDE_CAP:]
        exclude_block = (
            "Do NOT generate any of these already-collected dishes (choose a different one):\n"
            + ", ".join(sample) + "\n\n"
        )
    return f"""
Generate ONE authentic {cuisine} recipe as data.

{exclude_block}OUTPUT RULES (critical):
- Respond with ONLY a single JSON object inside one ```json code block.
- No prose, no titles, no numbering, no emojis. Start with {{ and end with }}.
- Include ALL keys exactly as in the example below, every value non-empty.
- "name" must be the dish name (not empty) and must NOT appear as a heading outside the JSON.
- Times are INTEGER minutes. ingredients is a FLAT array of objects (name/quantity/unit/aisle),
  not strings and not grouped by category.

Field rules:
- meal_type: Breakfast | Lunch | Dinner | Snack | Dessert | Drinks.
- difficulty: Easy | Medium | Hard.
- aisle: Produce | Dairy | Meat | Seafood | Pantry | Bakery | Frozen | Spices | Other.
- diet_flags subset of: Vegetarian, Vegan, Gluten-Free, Keto, High-Protein, Low-Carb, Dairy-Free.
- allergens subset of: Peanuts, Tree Nuts, Dairy, Gluten, Shellfish, Fish, Eggs, Soy, Sesame.
- halal_haram_status: Halal | Haram | Mashbooh.
    Haram = pork, alcohol, blood, or non-halal-slaughtered meat.
    Mashbooh = doubtful source (gelatin, rennet, enzymes, unspecified vanilla extract).
    Otherwise Halal. halal_haram_reason: one line naming the key ingredient.
- nutrition_per_serving: numeric grams per serving.
- cuisine must be "{cuisine}".

Copy this exact JSON structure (return ONE new dish like this):

```json
{_EXAMPLE_ONE}
```

Output the single JSON object for a NEW {cuisine} recipe only.
""".strip()


# ---------------------------------------------------------------------------
# Browser plumbing
# ---------------------------------------------------------------------------
def connect_to_chrome():
    cmd = f'"{CHROME_PATH}" --remote-debugging-port={REMOTE_DEBUGGING_PORT} --user-data-dir="{USER_DATA_DIR}"'
    subprocess.Popen(cmd, shell=True)
    print("Chrome launched with remote debugging.")
    input("Log in to ChatGPT, open a chat, then press Enter here (keep Chrome open)...")

    options = Options()
    options.add_experimental_option("debuggerAddress", f"localhost:{REMOTE_DEBUGGING_PORT}")
    driver = webdriver.Chrome(options=options)
    print(f"Connected to Chrome. Page title: {driver.title}")
    return driver


def random_delay(lo=2, hi=4):
    time.sleep(random.uniform(lo, hi))


def send_prompt(driver, prompt_text):
    """Type the prompt into the ChatGPT input box and submit."""
    for attempt in range(3):
        try:
            box = WebDriverWait(driver, 15).until(
                EC.visibility_of_element_located((By.ID, "prompt-textarea"))
            )
            box.click()
            box.clear()
            box.send_keys(prompt_text)
            random_delay(1, 2)
            box.send_keys(Keys.RETURN)
            print("Prompt sent.")
            return True
        except (StaleElementReferenceException, TimeoutException):
            print(f"Retry sending prompt ({attempt + 1}/3)...")
            time.sleep(3)
        except Exception as e:  # noqa: BLE001
            logging.error(f"Error sending prompt: {e}")
    return False


def _strip_fences(text):
    text = text.strip()
    if text.startswith("```json"):
        text = text[7:]
    if text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    return text.strip()


def _extract_balanced(text, open_ch, close_ch):
    """Return the first complete, balanced open_ch...close_ch substring."""
    start = text.find(open_ch)
    if start == -1:
        return None
    depth, in_str, esc = 0, False, False
    for i in range(start, len(text)):
        ch = text[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
        else:
            if ch == '"':
                in_str = True
            elif ch == open_ch:
                depth += 1
            elif ch == close_ch:
                depth -= 1
                if depth == 0:
                    return text[start:i + 1]
    return None


def _parse_recipes(text):
    """Extract recipe dicts from a chunk of text. Handles:
       - a JSON array of objects, or
       - a single JSON object (one recipe per code block).
    Returns a list of dicts (possibly empty)."""
    raw = _strip_fences(text)
    if not raw:
        return []

    # 1) Whole chunk is valid JSON?
    try:
        data = json.loads(raw)
        if isinstance(data, list):
            return [x for x in data if isinstance(x, dict)]
        if isinstance(data, dict):
            return [data]
    except json.JSONDecodeError:
        pass

    # 2) A top-level array appearing before any bare object?
    arr_pos = raw.find("[")
    obj_pos = raw.find("{")
    if arr_pos != -1 and (obj_pos == -1 or arr_pos < obj_pos):
        arr = _extract_balanced(raw, "[", "]")
        if arr:
            try:
                data = json.loads(arr)
                if isinstance(data, list):
                    dicts = [x for x in data if isinstance(x, dict)]
                    if dicts:
                        return dicts
            except json.JSONDecodeError:
                pass

    # 3) A single balanced object (one recipe per code block).
    obj = _extract_balanced(raw, "{", "}")
    if obj:
        try:
            data = json.loads(obj)
            if isinstance(data, dict):
                return [data]
        except json.JSONDecodeError:
            pass
    return []


def count_assistant_messages(driver):
    return len(driver.find_elements(By.CSS_SELECTOR, "div[data-message-author-role='assistant']"))


def extract_response(driver, prev_count=0, max_wait=240, poll=4, stable_needed=2):
    """Wait for a NEW assistant message to finish streaming, then parse its JSON.

    A long response (8 recipes) streams in for a while; parsing too early gets
    truncated JSON. We wait until a new message appears AND its text stops
    changing for a couple of polls (streaming complete) before parsing.
    """
    print("Waiting for ChatGPT response...")
    deadline = time.time() + max_wait
    last_text, stable = None, 0
    while time.time() < deadline:
        messages = driver.find_elements(By.CSS_SELECTOR, "div[data-message-author-role='assistant']")
        if len(messages) > prev_count:
            latest = messages[-1]
            text = latest.text or ""
            if text.strip() and text == last_text:
                stable += 1
            else:
                stable = 0
                last_text = text
                print(f"[stream] receiving... {len(text)} chars", end="\r")
            if stable >= stable_needed:
                codes = latest.find_elements(By.CSS_SELECTOR, "code")
                code_texts = [c.text for c in codes]

                # --- Diagnostics so we can see exactly what ChatGPT returned ---
                print("-" * 60)
                print(f"[response] message length: {len(text)} chars")
                print(f"[response] code blocks found: {len(code_texts)} "
                      f"(lengths: {[len(c) for c in code_texts]})")
                print(f"[response] message preview:\n{text[:400]}")
                print("." * 60)
                for i, ct in enumerate(code_texts):
                    print(f"[response] code block {i} preview:\n{ct[:400]}")
                print("-" * 60)
                # ---------------------------------------------------------------

                # Collect a recipe from EACH code block (ChatGPT often emits one
                # object per block), then fall back to the whole message.
                collected = []
                for ct in code_texts:
                    collected.extend(_parse_recipes(ct))
                if not collected:
                    collected = _parse_recipes(text)
                if collected:
                    print(f"[response] parsed {len(collected)} recipe object(s).")
                    return collected

                # Couldn't parse — dump everything we saw for inspection.
                dump = os.path.join(DATA_DIR, "_debug_unparsed.txt")
                with open(dump, "w", encoding="utf-8") as f:
                    f.write("=== MESSAGE TEXT ===\n" + text + "\n\n")
                    for i, ct in enumerate(code_texts):
                        f.write(f"=== CODE BLOCK {i} ===\n{ct}\n\n")
                print(f"[response] could not parse JSON. Saved raw text to {dump}")
                return []
        time.sleep(poll)
    print("Timed out waiting for a complete response.")
    return []


# ---------------------------------------------------------------------------
# Validation / cleaning
# ---------------------------------------------------------------------------
def _num(value, default=0):
    try:
        if isinstance(value, str):
            value = re.sub(r"[^0-9.\-]", "", value) or default
        return round(float(value), 2)
    except (TypeError, ValueError):
        return default


def _int(value, default=0):
    return int(_num(value, default))


def _minutes(value, default=0):
    """Parse a time value to integer minutes.
    Handles 45, "30 min", "1 hour 20 min", "6-8 hours" (takes the first number)."""
    if isinstance(value, (int, float)):
        return int(value)
    if isinstance(value, str):
        s = value.lower()
        nums = re.findall(r"\d+\.?\d*", s)
        if not nums:
            return default
        total = float(nums[0])
        if "hour" in s or "hr" in s:
            total *= 60
            if len(nums) > 1 and ("min" in s):  # "1 hour 20 min"
                total += float(nums[1])
        return int(total)
    return default


def _enum(value, allowed, default):
    if isinstance(value, str):
        for item in allowed:
            if value.strip().lower() == item.lower():
                return item
    return default


def _subset(values, allowed):
    out = []
    if isinstance(values, list):
        for v in values:
            match = _enum(v, allowed, None)
            if match and match not in out:
                out.append(match)
    return out


def _first(rec, keys, default=""):
    """Return the first present, non-empty value among alternative key names."""
    for k in keys:
        if isinstance(rec, dict) and rec.get(k) not in (None, "", [], {}):
            return rec.get(k)
    return default


def clean_ingredients(raw):
    out = []
    if isinstance(raw, dict):
        # Categorised ingredients, e.g. {"marinade": [...], "rice": [...]} → flatten.
        merged = []
        for value in raw.values():
            if isinstance(value, list):
                merged.extend(value)
            elif value:
                merged.append(value)
        raw = merged
    if isinstance(raw, str):
        raw = [s for s in re.split(r"[\n,]", raw) if s.strip()]
    if not isinstance(raw, list):
        return out
    for item in raw:
        if isinstance(item, dict):
            name = _first(item, ["name", "ingredient", "item", "title"])
            if not name:
                continue
            out.append({
                "name": str(name).strip(),
                "quantity": _num(_first(item, ["quantity", "amount", "qty"], 1), 1),
                "unit": str(_first(item, ["unit", "units", "measure"], "")).strip(),
                "aisle": _enum(_first(item, ["aisle", "category"], "Other"), AISLES, "Other"),
                "notes": str(_first(item, ["notes", "note", "preparation"], "")).strip(),
            })
        elif isinstance(item, str) and item.strip():
            out.append({"name": item.strip(), "quantity": 1, "unit": "", "aisle": "Other", "notes": ""})
    return out


def clean_steps(raw):
    """Accept steps as a list, or a single string split on newlines/numbering."""
    if isinstance(raw, list):
        steps = []
        for s in raw:
            if isinstance(s, dict):
                s = _first(s, ["step", "text", "instruction", "description"])
            if str(s).strip():
                steps.append(str(s).strip())
        return steps
    if isinstance(raw, str) and raw.strip():
        parts = re.split(r"\n+|(?<=[.!?])\s+(?=[A-Z0-9])", raw.strip())
        return [p.strip() for p in parts if p.strip()]
    return []


def clean_nutrition(raw):
    raw = raw if isinstance(raw, dict) else {}
    keys = ["calories", "protein_g", "carbs_g", "fat_g",
            "fiber_g", "sugar_g", "sodium_mg", "saturated_fat_g"]
    return {k: _num(raw.get(k), 0) for k in keys}


def validate_recipe(rec, cuisine, next_id):
    """Return (cleaned_recipe, None) or (None, reason) if too incomplete to keep."""
    if not isinstance(rec, dict):
        return None, f"not a dict ({type(rec).__name__})"
    name = str(_first(rec, ["name", "title", "recipe_name", "dish"], "")).strip()
    ingredients = clean_ingredients(_first(rec, ["ingredients", "ingredient_list"], []))
    steps = clean_steps(_first(rec, ["steps", "instructions", "method", "directions", "preparation"], []))
    if not name:
        return None, "missing name"
    if not ingredients:
        return None, "no ingredients"
    if not steps:
        return None, "no steps"

    prep = _minutes(_first(rec, ["prep_time_minutes", "prep_time", "prep"], 0))
    cook = _minutes(_first(rec, ["cook_time_minutes", "cook_time", "cook"], 0))

    cleaned = {
        "id": next_id,
        "name": name.title() if name.islower() else name,
        "description": str(_first(rec, ["description", "summary"], "")).strip(),
        "cuisine": str(_first(rec, ["cuisine"], cuisine)).strip() or cuisine,
        "country": str(_first(rec, ["country", "origin", "country_of_origin"], "")).strip(),
        "region": str(_first(rec, ["region"], "")).strip(),
        "meal_type": _enum(_first(rec, ["meal_type", "category"], ""), MEAL_TYPES, "Dinner"),
        "course": str(_first(rec, ["course"], "")).strip(),
        "difficulty": _enum(_first(rec, ["difficulty"], ""), DIFFICULTIES, "Medium"),
        "prep_time_minutes": prep,
        "cook_time_minutes": cook,
        "total_time_minutes": prep + cook,
        "servings": max(1, _int(_first(rec, ["servings", "serves", "yield"], 2), 2)),
        "ingredients": ingredients,
        "steps": steps,
        "tags": [str(t).strip() for t in _first(rec, ["tags"], []) if str(t).strip()],
        "diet_flags": _subset(_first(rec, ["diet_flags", "dietary"], []), DIET_FLAGS),
        "allergens": _subset(_first(rec, ["allergens"], []), ALLERGENS),
        "halal_haram_status": _enum(
            _first(rec, ["halal_haram_status", "halal_status", "halal"], ""), HALAL_STATUS, "Mashbooh"),
        "halal_haram_reason": str(_first(rec, ["halal_haram_reason", "halal_reason", "reason"], "")).strip(),
        "nutrition_per_serving": clean_nutrition(_first(rec, ["nutrition_per_serving", "nutrition"], {})),
        "nutrition_estimated": True,
        "image_query": str(_first(rec, ["image_query"], name)).strip(),
        "image_url": "",
        "rating": 0,
        "review_count": 0,
        "author": "AI-generated",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    return cleaned, None


def quality_issues(raw):
    """List the priority fields the model left missing/empty (drives the retry)."""
    if not isinstance(raw, dict):
        return ["not a dict"]
    issues = []
    if not str(_first(raw, ["name", "title", "dish"], "")).strip():
        issues.append("name")
    if not clean_ingredients(_first(raw, ["ingredients", "ingredient_list"], [])):
        issues.append("ingredients")
    if not clean_steps(_first(raw, ["steps", "instructions", "method", "directions"], [])):
        issues.append("steps")
    if not str(_first(raw, ["country", "origin", "country_of_origin"], "")).strip():
        issues.append("country")
    if not _enum(_first(raw, ["halal_haram_status", "halal_status", "halal"], ""), HALAL_STATUS, ""):
        issues.append("halal_haram_status")
    nut = _first(raw, ["nutrition_per_serving", "nutrition"], {})
    if not (isinstance(nut, dict) and _num(nut.get("calories"), 0) > 0):
        issues.append("nutrition")
    return issues


def request_one_recipe(driver, cuisine, exclude_names, exclude_lower, next_id):
    """Ask for ONE recipe; validate; retry up to MAX_ATTEMPTS_PER_RECIPE for
    complete data. Returns a cleaned recipe dict or None."""
    for attempt in range(MAX_ATTEMPTS_PER_RECIPE):
        prev = count_assistant_messages(driver)
        prompt = build_single_prompt(cuisine, exclude_names) if attempt == 0 else FIELD_FIX_SINGLE
        if not send_prompt(driver, prompt):
            return None

        batch = extract_response(driver, prev_count=prev)
        if not batch:  # prose reply — one reformat nudge
            prev = count_assistant_messages(driver)
            if send_prompt(driver, REFORMAT_PROMPT):
                batch = extract_response(driver, prev_count=prev)
        if not batch:
            print(f"  attempt {attempt + 1}: no JSON")
            continue

        raw = batch[0]
        with open(os.path.join(DATA_DIR, "_debug_last_batch.json"), "w", encoding="utf-8") as f:
            json.dump(raw, f, ensure_ascii=False, indent=2)

        issues = quality_issues(raw)
        name = str(_first(raw, ["name", "title", "dish"], "")).strip().lower()
        if name and name in exclude_lower:
            issues.append("duplicate")
        if not issues:
            rec, reason = validate_recipe(raw, cuisine, next_id)
            if rec is not None:
                return rec
            issues.append(reason or "invalid")
        print(f"  attempt {attempt + 1}: incomplete -> {issues}")
        random_delay(2, 4)
    return None


# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
def load_existing():
    """Load existing recipes to resume id numbering and de-duplicate by name."""
    recipes = []
    if os.path.exists(JSONL_PATH):
        with open(JSONL_PATH, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        recipes.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
    next_id = (max((r.get("id", 0) for r in recipes), default=0)) + 1
    seen = {r.get("name", "").strip().lower() for r in recipes}
    return recipes, next_id, seen


def save_recipe(rec):
    with open(JSONL_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")


def rewrite_consolidated(recipes):
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(recipes, f, ensure_ascii=False, indent=2)


def log_missed(cuisine, reason):
    row = pd.DataFrame([{"cuisine": cuisine, "reason": reason, "timestamp": datetime.now()}])
    if os.path.exists(MISSED_PATH) and os.path.getsize(MISSED_PATH) > 0:
        row = pd.concat([pd.read_csv(MISSED_PATH), row], ignore_index=True)
    row.to_csv(MISSED_PATH, index=False)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    recipes, next_id, seen = load_existing()
    print(f"Loaded {len(recipes)} existing recipes. Next id = {next_id}.")

    driver = connect_to_chrome()
    saves_since_rewrite = 0

    try:
        for cuisine in CUISINES:
            # Names already collected for this cuisine (used to exclude duplicates).
            names = [r["name"] for r in recipes if r.get("cuisine") == cuisine]
            consec_fails = 0

            while len(names) < TARGET_PER_CUISINE:
                done = len(names)
                print(f"\n=== {cuisine}: {done}/{TARGET_PER_CUISINE} (total {len(recipes)}) ===")
                exclude_lower = {n.strip().lower() for n in names}

                rec = request_one_recipe(driver, cuisine, names, exclude_lower, next_id)
                if rec is None:
                    consec_fails += 1
                    log_missed(cuisine, "failed_after_retries")
                    print(f"  -> gave up on this recipe ({consec_fails}/{MAX_CONSEC_FAILS})")
                    if consec_fails >= MAX_CONSEC_FAILS:
                        print(f"Skipping {cuisine} after repeated failures.")
                        break
                    continue

                key = rec["name"].strip().lower()
                if key in seen:
                    print(f"  -> duplicate slipped through: {rec['name']}, skipping")
                    consec_fails += 1
                    if consec_fails >= MAX_CONSEC_FAILS:
                        break
                    continue

                consec_fails = 0
                seen.add(key)
                rec["id"] = next_id
                next_id += 1
                save_recipe(rec)
                recipes.append(rec)
                names.append(rec["name"])
                saves_since_rewrite += 1
                print(f"  + {rec['name']}  [{rec['country']} | {rec['halal_haram_status']} | "
                      f"{rec['nutrition_per_serving']['calories']} kcal]")

                if saves_since_rewrite >= SAVE_EVERY:
                    rewrite_consolidated(recipes)
                    saves_since_rewrite = 0
                random_delay(3, 6)

        print(f"\nDone. {len(recipes)} recipes saved to {JSONL_PATH}")
    except KeyboardInterrupt:
        print("\nStopped by user.")
    finally:
        rewrite_consolidated(recipes)
        print(f"Consolidated {len(recipes)} recipes -> {JSON_PATH}")


if __name__ == "__main__":
    main()
