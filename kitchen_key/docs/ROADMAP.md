# Kitchen Key — Complete Build Roadmap (Flutter + Django, Android)

## Context

**Goal:** Ship a complete, presentable Final-Year-Project mobile app, "Kitchen Key," covering the full 17-section feature guide — from empty scaffold to demo-ready.

---

## ⏱️ Current Status (updated)

**Track A — Flutter UI (this is where active work happens): "Premium Editorial" build with mock data.**
Done so far:
- Design system overhaul — Fraunces serif display + Inter body, warm cream palette, soft shadows, light/dark theme with a Settings toggle (`core/theme/`).
- Reusable widgets: `EditorialHeader`, `RecipeHeroImage` (shared-element transitions), `EmptyState`, `RatingStars`, `PrimaryButton`, skeleton loaders (`shared/widgets/`).
- Screens: Splash, Onboarding, Login, Register, Home (editorial, recipe-of-the-day hero + Generate CTA), Search, Saved, Meal Planner, Profile, Recipe Detail (hero image + reviews + servings scaler).
- **New feature screens:** Cooking Mode (timer + TTS read-aloud + keep-awake), Recipe Generation ("what's in your fridge"), Shopping List (aisle-grouped, check-off), Hydration tracker (progress ring), Nutrition Dashboard (`fl_chart` weekly chart + macros), Reviews & write-review sheet, Profile Edit, Settings.
- All navigation wired (`core/router/app_router.dart`); `flutter analyze` clean; smoke test passing.
- **Still mock data — no API calls yet.** Models use `fromJson`-friendly field names for an easy later swap.

**Track B — Backend (owned by the user, built separately): already exists.**
Django 6 + DRF + scikit-learn recommender (TF-IDF + SVD + cosine) over the **Food.com dataset**, served from pickle artifacts. Working public API at `/api/v1/` (`ingredients/`, `recipes/` with search/filter/pagination, `recipes/<id>/`, POST `recommend/`) + Swagger. **Gaps for later integration:** no CORS, no JWT auth, no user-data endpoints (saved/meal-plan/hydration/reviews/profile).

**Next phase (when the user is ready):** wire the Flutter app to the API — add a Dio client + repositories, map the backend's Food.com recipe shape (name/minutes/ingredient-strings/7-value nutrition/tags) onto the UI models, and add CORS + auth on the backend. The sections below remain the longer-term feature plan.

---

**Original starting state:** Clean default Flutter scaffold at `kitchen_key/` (Flutter 3.44.4 / Dart 3.12.2).

**Confirmed decisions:**
- **Backend:** Custom **Django + Django REST Framework (DRF)** with the user's **own recipe dataset**.
- **Recipe/nutrition data:** the user's dataset (loaded into Postgres), **not** Spoonacular/Edamam.
- **Platform:** **Android only.**
- **Scope:** **attempt the full list** (17 sections), with low-feasibility items delivered as simplified versions.

**Why this plan looks the way it does:** the feature guide is ~120 features across 17 sections — far more than a typical solo FYP delivers cleanly. This roadmap (a) resolves the conflicts/ambiguities in the document, (b) marks each feature's feasibility, and (c) sequences everything into phases so the **graded core demos perfectly** even if late-phase extras stay shallow.

---

## 1. Feasibility & Conflict Resolution (read this first)

The document has genuine conflicts and a few low-feasibility asks. Resolutions below are baked into the roadmap.

### 1.1 Requirement conflicts found

| # | Conflict in the doc | Resolution |
|---|---------------------|------------|
| C1 | Duplicate use-case IDs: Recommendations = **UC-9**, Meal Planner = **UC-09**, both used. | Renumber canonically (see §2). Meal Planner → UC-13, Recommendations stays UC-9. |
| C2 | Recipe data: doc says **third-party API (Spoonacular/Edamam)** *and* **AI generation (OpenAI)**. | **Neither.** Use the user's **own dataset in Postgres**. "Recipe Generation (UC-5)" becomes **ingredient-match + filtering over the dataset** (an algorithm), with an optional LLM as a stretch only. |
| C3 | "JWT auth" + "Login with Google/Facebook" + "email verification". | All via Django: **SimpleJWT** (access+refresh) + **dj-rest-auth/allauth** (Google social login; Facebook optional/skip), + Django email verification. |
| C4 | "Admin Panel" (Section 15) described as a separate dashboard. | **Django Admin** delivers recipe/user/content CRUD + moderation for near-zero cost. Analytics dashboard = a small admin page / DRF endpoints + charts. |
| C5 | "Offline support with queue + sync" vs cloud-first design. | Scope offline to **read cached saved/viewed recipes + queued save/unsave**. Full offline meal-plan *editing* = stretch. |
| C6 | Nutrition info required across app (recipe details, meal planner, tracking). | **Hard dependency on the dataset containing nutrition columns.** If the dataset lacks them, either pick a dataset that has them or mark values "estimated." **Verify this in Phase 1.** |

### 1.2 Low-feasibility features → simplified delivery

| Feature (doc) | Issue | Delivered as |
|---------------|-------|--------------|
| 7.2 "Compare prices across stores" / "nearby grocery stores" | No free, reliable price/retail API in PK market. | **Manual per-ingredient cost estimate** field + total. Drop live price comparison. |
| 7.2 Barcode scanner | Feasible but needs a product DB. | `mobile_scanner` + **Open Food Facts** lookup. Mark **optional/stretch**. |
| 11.2 Family/group real-time collaborative planning | Real-time multi-user sync is heavy. | **Group membership + shared lists/plans (refresh-based, not live).** |
| 7.1 Voice control / 12.1 full voice control | STT reliability + scope. | **TTS recipe read-aloud** (`flutter_tts`) = core; **speech-to-text** = stretch. |
| 16.1 Payment gateway | Out of scope (app isn't monetized). | **Excluded.** |
| 6.2 / 16.1 Health-app & analytics SDK integrations | Optional, time sink. | **Excluded or stubbed** (internal nutrition tracking only). |

### 1.3 Tech feasibility verdict
Everything **core** is comfortably achievable in Flutter + DRF. Risk concentrates in late phases (offline sync, groups, notifications scheduling). The phase order front-loads graded value so a slip in Phase 6+ doesn't break the demo.

---

## 2. Canonical Use-Case Map (renumbered)

UC-1 Register · UC-2 Login · UC-3 Search · UC-4 Password Reset · UC-5 Recipe Generation (dataset match) · UC-6 View Recipe · UC-7 Save/Unsave · UC-8 View Saved · UC-9 Recommendations · UC-10 Hydration · UC-11 Nutrition Tracking · UC-12 Profile · UC-13 Meal Planner · UC-14 Shopping List · UC-15 Ratings/Reviews · UC-16 Notifications · UC-17 Offline · UC-18 Groups · UC-19 Admin.

---

## 3. Target Architecture

```
┌─────────────────────────────┐        HTTPS / JWT        ┌──────────────────────────────┐
│   Flutter App (Android)     │  ───────────────────────► │   Django + DRF API           │
│                             │                           │                              │
│  Presentation (screens)     │  ◄─── JSON / paginated ── │  Auth (SimpleJWT + allauth)  │
│  Riverpod controllers       │                           │  Recipe/Search/Reco services │
│  Repositories               │                           │  MealPlan/Shopping/Hydration │
│  Remote (Dio) + Local(Hive) │                           │  Ratings/Groups/Notifications│
└──────────┬──────────────────┘                           │  Django Admin (Section 15)   │
           │ FCM push                                      └──────────────┬───────────────┘
           ▼                                                              ▼
   Firebase Cloud Messaging  ◄──── server sends via FCM ────      PostgreSQL  (+ recipe dataset)
                                                                  Cloudinary/S3 (images)
```

**Frontend:** Flutter, **Riverpod 2.x** state mgmt, **go_router** navigation, **Dio** networking, **Hive** local cache + **flutter_secure_storage** for tokens. Clean feature-first layering: `presentation → controller → repository → datasource`.

**Backend:** Django + DRF, **PostgreSQL**, **SimpleJWT** + **dj-rest-auth/allauth**, **django-filter** (search/filters), **fcm-django** (push), **Cloudinary** (images), **Celery + Redis** *or* a cron'd management command for digests/scheduled notifications. **Django Admin** = the admin panel.

**Hosting:** Backend on Render/Railway/PythonAnywhere free tier; Postgres managed on same; Cloudinary free tier for images.

---

## 4. Tech Stack & Key Packages

**Flutter:** `flutter_riverpod`, `go_router`, `dio`, `hive`/`hive_flutter`, `flutter_secure_storage`, `connectivity_plus`, `firebase_core`, `firebase_messaging`, `flutter_local_notifications`, `cached_network_image`, `image_picker`, `flutter_tts`, `fl_chart`, `table_calendar`, `share_plus`, `url_launcher`, `shimmer`, `intl`, `google_sign_in`, `mobile_scanner` (stretch), `speech_to_text` (stretch).

**Django:** `djangorestframework`, `djangorestframework-simplejwt`, `dj-rest-auth`, `django-allauth`, `django-cors-headers`, `django-filter`, `Pillow`, `psycopg2-binary`, `python-decouple`, `cloudinary`, `fcm-django`, `celery`+`redis` (or `django-crontab`), `drf-spectacular` (auto API docs — great for the FYP report).

---

## 5. Backend Data Model (Postgres / Django models)

- **User** (Django auth) + **Profile** (photo, dietary_prefs[], allergies[], skill_level, calorie_goal, water_goal, notif_prefs)
- **Recipe** (title, description, image, prep_time, cook_time, difficulty, cuisine FK, meal_type, servings, instructions[], tips, video_url) — *seeded from dataset*
- **Ingredient**, **RecipeIngredient** (qty, unit, est_cost), **Cuisine**, **Tag/DietFlag**
- **NutritionInfo** (per recipe: calories, protein, carbs, fat, fiber, sugar) — *from dataset (see C6)*
- **SavedRecipe** (user, recipe, category: favorite/want-to-try/made-before, note, last_cooked, cook_count)
- **Rating**, **Review** (text, votes), **ReviewPhoto**
- **MealPlan** (user, week_start), **MealPlanEntry** (plan, date, slot, recipe, servings)
- **ShoppingList**, **ShoppingListItem** (name, qty, section, checked, custom)
- **HydrationLog** (user, date, glasses), **WaterGoal**
- **SearchHistory**, **RecipeView** (for recommendations)
- **Group**, **GroupMembership** (shared plans/lists)
- **DeviceToken** (FCM), **Notification**

**Dataset loading:** a `manage.py import_recipes` management command parses the dataset (CSV/JSON) → Recipe/Ingredient/Nutrition rows. **Phase 1 deliverable.**

---

## 6. Flutter App Structure

```
lib/
  core/        theme (light/dark), router (go_router), dio client+interceptors,
               constants, errors, result types
  data/        models (json), repositories, datasources (remote api, local hive)
  features/
    auth/  search/  recipe/  saved/  recommendations/  profile/
    meal_plan/  shopping/  hydration/  nutrition/  cooking_assistant/
    reviews/  notifications/  groups/  onboarding/  settings/
  shared/      widgets (cards, buttons, shimmer, empty/error states)
  main.dart
```
**Navigation:** 5-tab bottom nav — Home/Recommendations · Search · Meal Planner · Saved · Profile — + drawer for settings/extras.

---

## 7. Phased Roadmap

Estimates assume one developer. Adjust week counts to your submission deadline; the **order** matters more than the exact dates. Each feature is tagged **[Core] / [Simplified] / [Stretch]**. Maps to all 17 doc sections.

### Phase 0 — Foundation & Setup *(Week 1)*
- `git init`, repo + `.gitignore`, branching; create Django project + DRF + Postgres; create Flutter app skeleton (folders, theme, router, Dio client).
- Decide env config (`.env`), CORS, base URL. Stand up Django Admin. Auto API docs via drf-spectacular.
- **Exit:** Flutter app boots to a placeholder shell talking to a `/health` endpoint; Django Admin reachable.

### Phase 1 — Data + Auth Backbone *(Weeks 2–3)* → **doc §1, §14, §16**
- **[Core]** Import recipe dataset (`import_recipes` command); **verify nutrition columns exist (C6)**.
- **[Core]** Auth: register + **email verification**, login (JWT access/refresh), password reset (token, 1h expiry), logout + token blacklist, refresh-on-401 interceptor, secure token storage.
- **[Core]** Security baseline: HTTPS, input validation/serializers, DRF throttling (rate limit), session timeout, 5-attempt lockout.
- **[Simplified]** Google social login (`dj-rest-auth`); **[Stretch]** Facebook.
- **Exit:** A user can register → verify email → log in → token auto-refreshes. Demoable.

### Phase 2 — Recipe Discovery *(Weeks 3–5)* → **doc §2, §3.1–3.3**
- **[Core]** UC-3 Search: by name + by ingredients; filters (cuisine, diet, meal type, time, difficulty); sort (relevance/popularity/rating/newest); pagination/infinite scroll; auto-suggest; recent + popular searches; empty/no-results states. (DRF `SearchFilter`/`django-filter` + endpoints.)
- **[Core]** UC-6 Recipe details: image, times, difficulty, badges, ingredients w/ quantities, **nutrition**, step-by-step, tips, **servings adjuster (auto-scale quantities)**, share, print/export.
- **[Core]** UC-7/UC-8 Save/Unsave + Saved screen: categories, notes, grid/list toggle, search-within-saved, last-cooked/frequency.
- **[Core]** UC-5 Recipe Generation = **ingredient-match algorithm** over dataset ("what's in your fridge") + save/regenerate/rate. **[Stretch]** LLM-generated variant.
- **Exit:** Full browse → search → view → save loop works end-to-end. This is the graded heart of the app.

### Phase 3 — Personalization *(Week 5–6)* → **doc §4**
- **[Core]** UC-9 Recommendations: from saved + view/search history + dietary prefs + skill level; "trending", "quick meals", "healthy"; refresh; "why recommended?" tooltip. (Server-side scoring endpoint; start rule-based.)
- **[Core]** UC-12 Profile: photo upload (Cloudinary), edit details, dietary/allergy/skill updates, change password, change email (re-auth), notification prefs, privacy, **account deletion + data export (GDPR, §14.1)**.
- **Exit:** Home feed personalizes; profile fully editable.

### Phase 4 — Meal Planning & Shopping *(Weeks 6–8)* → **doc §5**
- **[Core]** UC-13 Meal Planner: weekly calendar (`table_calendar`), assign recipes to breakfast/lunch/dinner, per-day + weekly nutrition totals, save/history, copy week, serving adjust. **[Simplified]** auto-generate plan from prefs (rule-based). **[Stretch]** drag-and-drop (start with tap-to-assign).
- **[Core]** UC-14 Shopping List: generate from meal plan, merge/dedupe ingredients, group by store section, check off, add custom items, multiple lists, share/export.
- **Exit:** Plan a week → generate a consolidated shopping list.

### Phase 5 — Smart & Health Features *(Weeks 8–10)* → **doc §6, §7**
- **[Core]** UC-10 Hydration: goal, log glasses, progress ring, history, reminders (interval, quiet hours, sound, custom message) via local notifications.
- **[Core]** UC-11 Nutrition tracking: daily calorie goal, log meals from recipes, daily/weekly summary, `fl_chart` macro charts, progress over time.
- **[Core]** Cooking Assistant: in-app timer, cooking mode (large text, keep-screen-on), **TTS read-aloud**, substitution suggestions, scale recipe. **[Stretch]** STT voice control.
- **[Simplified]** Smart shopping: have/need checklist, low-stock flags, **manual cost estimate**. **[Stretch]** barcode scan (Open Food Facts).
- **Exit:** Health/cooking utilities functional.

### Phase 6 — Social, Notifications, Offline *(Weeks 10–12)* → **doc §8, §9, §10, §11.2**
- **[Core]** UC-15 Ratings/Reviews: 1–5 stars, text, dish photos, sort, upvote, report. Moderation via Django Admin.
- **[Core]** Recipe/plan/list sharing via `share_plus` + deep/copy links.
- **[Core]** UC-16 Notifications: FCM push (recommendations, meal reminders, hydration, new matching recipes, digests), prefs management. Scheduling via Celery/cron.
- **[Simplified]** UC-17 Offline: cache saved + viewed recipes (Hive), offline view + offline search-within-cache, queued save/unsave sync, connection indicator, last-synced. **[Stretch]** offline meal-plan edits.
- **[Simplified]** UC-18 Groups: create group, shared recipes/lists/plans (refresh-based), assign cooking duties. **[Stretch]** live collaboration.
- **Exit:** Community + notifications + graceful offline.

### Phase 7 — Admin, Accessibility, UX Polish *(Week 12–13)* → **doc §11.1, §12, §13, §15**
- **[Core]** UC-19 Admin (Django Admin): recipe CRUD/approve, user view/suspend/delete, review moderation, notification broadcast, basic analytics (popular recipes, active users) via admin views/DRF + charts. **(§11.1 analytics rolls in here.)**
- **[Core]** §13 UX: onboarding (welcome, permissions, diet/skill selection), light/dark + system theme, Material 3, skeleton/shimmer loaders, smooth transitions, swipe/drawer nav.
- **[Simplified]** §12 Accessibility: large-text/font scaling, high-contrast, color-blind-safe palette, screen-reader labels, TTS. **[Stretch]** full voice control.
- **Exit:** App feels finished; admin can run the system.

### Phase 8 — Testing, Hardening, Demo Prep *(Weeks 13–14)* → **doc §17**
- **[Core]** Backend: DRF `APITestCase` for auth, search, save, meal plan, reviews; throttling/lockout tests.
- **[Core]** Flutter: unit (repos), widget (key screens), `integration_test` happy paths.
- **[Core]** Manual UC test matrix from §17 (success/failure/validation/lockout/offline).
- **[Core]** Build signed Android release APK; seed demo data; rehearse demo script; finalize API docs + report screenshots.
- **Exit:** Stable signed APK + green test suite + demo script.

---

## 8. Feature → Phase Coverage (all 17 doc sections accounted for)

| Doc § | Topic | Phase | Tag |
|------|-------|-------|-----|
| 1 | Authentication | 1 | Core |
| 2 | Search & Generation | 2 | Core / gen=Simplified |
| 3 | Recipe mgmt (view/save) | 2 | Core |
| 4 | Personalization/Profile | 3 | Core |
| 5 | Meal plan + shopping | 4 | Core / drag=Stretch |
| 6 | Health & wellness | 5 | Core |
| 7 | Smart features | 5 | Core / price+barcode=Simplified/Stretch |
| 8 | Social & community | 6 | Core |
| 9 | Offline | 6 | Simplified |
| 10 | Notifications | 6 | Core |
| 11 | Analytics + Groups | 6–7 | Groups=Simplified, analytics in Admin |
| 12 | Accessibility | 7 | Simplified |
| 13 | UI/UX | 7 | Core |
| 14 | Data & security | 1 (+3 GDPR) | Core |
| 15 | Admin panel | 7 | Core (Django Admin) |
| 16 | Integrations | 1/6 | Core (email, FCM, Cloudinary); payment=Excluded |
| 17 | Testing | 8 | Core |

---

## 9. Risk Register & Cut List (if behind schedule)

| Risk | Mitigation |
|------|------------|
| Dataset lacks nutrition/images | Verify Phase 1; fall back to "estimated"/placeholder images. |
| Notification scheduling complexity (Celery/Redis) | Fall back to `django-crontab` + local notifications. |
| Free-tier hosting cold starts during demo | Pre-warm before demo; have local backend as backup. |
| Time overrun | **Cut in this order:** Stretch items → Groups → Offline editing → Barcode → social login(Facebook) → analytics depth. **Never cut** Phases 1–4. |

---

## 10. Verification Strategy

- **Backend:** `python manage.py test` (DRF `APITestCase`); run `runserver`, exercise endpoints via the auto-generated drf-spectacular Swagger UI + curl/Postman; confirm JWT refresh, throttling, lockout, email verification token flow.
- **Frontend:** `flutter test` (unit + widget) and `flutter test integration_test` on an Android emulator; `flutter run` for manual UC walkthroughs.
- **End-to-end demo script** (the §17 matrix): register→verify→login→search→view→save→generate→plan week→shopping list→hydration log→review→push notification→go offline/online. Each step is a checklist item for the final demo.
- **Release check:** `flutter build apk --release`, install on a physical Android device, run the demo script once more.

---

## 11. Immediate Next Steps (Phase 0)

1. `git init` the repo; add Flutter + Django `.gitignore`s.
2. Scaffold Django project (`config/`, `apps/`), install DRF + SimpleJWT + Postgres, wire `.env`, enable Django Admin + drf-spectacular.
3. Restructure Flutter `lib/` into the §6 layout; add core deps (riverpod, go_router, dio, hive, secure_storage); build app shell with 5-tab nav + theme.
4. Confirm dataset format and **inspect it for nutrition + image fields** before writing the import command.

> Note on "attempt the full list": this plan covers all 17 sections, but honestly grades best if Phases 1–4 are flawless. Treat Phase 6+ Stretch items as bonus, not blockers.
