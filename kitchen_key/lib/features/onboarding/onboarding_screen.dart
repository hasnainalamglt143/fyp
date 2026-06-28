import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class _OnboardPage {
  final String image;
  final String title;
  final String subtitle;
  const _OnboardPage(this.image, this.title, this.subtitle);
}

/// Three-page swipeable intro highlighting the app's core value.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardPage(
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
      'Discover great recipes',
      'Thousands of dishes filtered by cuisine, diet and the time you have.',
    ),
    _OnboardPage(
      'https://images.unsplash.com/photo-1466637574441-749b8f19452f?w=800&q=80',
      'Cook with what you have',
      'Tell us your ingredients and we will generate a recipe just for you.',
    ),
    _OnboardPage(
      'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=800&q=80',
      'Plan your whole week',
      'Build meal plans, auto-generate shopping lists and stay on track.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm, top: AppSpacing.sm),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Fixed size image that won't overflow
                          SizedBox(
                            height: screenHeight * 0.35, // 35% of screen height
                            child: ClipRRect(
                              borderRadius: AppRadius.brXl,
                              child: CachedNetworkImage(
                                imageUrl: page.image, 
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24), // Fixed spacing
                          Text(
                            page.title,
                            textAlign: TextAlign.center, 
                            style: text.headlineMedium,
                          ),
                          const SizedBox(height: 12), // Fixed spacing
                          Text(
                            page.subtitle,
                            textAlign: TextAlign.center, 
                            style: text.bodyMedium,
                          ),
                          const SizedBox(height: 20), // Extra bottom space
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.border,
                          borderRadius: AppRadius.brSm,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24), // Fixed spacing
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(_index == _pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}