import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _agree = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join Kitchen Key', style: text.headlineMedium),
                const SizedBox(height: 6),
                Text('Start your cooking journey in seconds', style: text.bodyMedium),
                AppSpacing.vGapXl,
                AppTextField(
                  label: 'Username',
                  hint: 'chef_ali',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                AppSpacing.vGapLg,
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                AppSpacing.vGapLg,
                AppTextField(
                  label: 'Password',
                  hint: 'Min 8 chars, 1 upper, 1 number',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  controller: _passwordCtrl,
                  suffix: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'At least 8 characters' : null,
                ),
                AppSpacing.vGapLg,
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null,
                ),
                AppSpacing.vGapLg,
                Row(
                  children: [
                    Checkbox(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: text.bodyMedium,
                          children: [
                            TextSpan(
                              text: 'Terms & Privacy Policy',
                              style: text.labelMedium?.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapLg,
                ElevatedButton(
                  onPressed: _agree ? _submit : null,
                  child: const Text('Create Account'),
                ),
                AppSpacing.vGapMd,
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: text.bodyMedium),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text('Sign In',
                            style: text.labelLarge?.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
          icon: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 48),
          title: const Text('Verify your email'),
          content: const Text(
            'We sent a verification link to your email. Confirm it to activate your account.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/login');
                },
                child: const Text('Back to Sign In'),
              ),
            ),
          ],
        ),
      );
    }
  }
}
