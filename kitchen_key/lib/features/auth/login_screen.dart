import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _remember = true;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.vGapLg,
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 32),
                ),
                AppSpacing.vGapXl,
                Text('Welcome back 👋', style: text.displaySmall ?? text.headlineMedium),
                const SizedBox(height: 6),
                Text('Sign in to continue cooking with Kitchen Key', style: text.bodyMedium),
                AppSpacing.vGapXxl,
                const AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                AppSpacing.vGapLg,
                AppTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                AppSpacing.vGapSm,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _remember,
                          onChanged: (v) => setState(() => _remember = v ?? false),
                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                        ),
                        Text('Remember me', style: text.bodyMedium),
                      ],
                    ),
                    TextButton(
                      onPressed: () => _showForgotSheet(context),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                AppSpacing.vGapLg,
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Sign In'),
                ),
                AppSpacing.vGapXl,
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('or continue with', style: text.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                AppSpacing.vGapXl,
                Row(
                  children: [
                    Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata_rounded, onTap: () {})),
                    AppSpacing.hGapMd,
                    Expanded(child: _SocialButton(label: 'Facebook', icon: Icons.facebook_rounded, onTap: () {})),
                  ],
                ),
                AppSpacing.vGapXxl,
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: text.bodyMedium),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: Text('Sign Up',
                            style: text.labelLarge?.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ].animate(interval: 60.ms).fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset password', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Enter your email and we will send you a secure reset link.',
                style: Theme.of(ctx).textTheme.bodyMedium),
            AppSpacing.vGapXl,
            const AppTextField(
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            AppSpacing.vGapLg,
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset link sent to your email')),
                );
              },
              child: const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    );
  }
}
