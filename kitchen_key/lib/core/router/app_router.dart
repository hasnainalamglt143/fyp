import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/recipe.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/generate/recipe_generation_screen.dart';
import '../../features/hydration/hydration_screen.dart';
import '../../features/nutrition/nutrition_dashboard_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/profile/profile_edit_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/recipe/recipe_detail_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shopping/shopping_list_screen.dart';

/// Central navigation graph. Flow: splash → onboarding → auth → main shell,
/// with feature screens pushed on top.
class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, _) => const AppShell()),
      GoRoute(
        path: '/recipe',
        pageBuilder: (_, state) =>
            buildFadeThroughPage(RecipeDetailScreen(recipe: state.extra as Recipe), state),
      ),
      GoRoute(path: '/generate', builder: (_, _) => const RecipeGenerationScreen()),
      GoRoute(path: '/shopping', builder: (_, _) => const ShoppingListScreen()),
      GoRoute(path: '/hydration', builder: (_, _) => const HydrationScreen()),
      GoRoute(path: '/nutrition', builder: (_, _) => const NutritionDashboardScreen()),
      GoRoute(path: '/profile/edit', builder: (_, _) => const ProfileEditScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
}

/// Shared fade+slide page transition helper for a polished feel.
Page<void> buildFadeThroughPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}
