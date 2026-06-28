import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/app_text_field.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _selectedDiet = {'Vegetarian', 'High-Protein'};
  final _selectedAllergies = {'Peanuts'};
  String _skill = 'Intermediate';

  static const _allergies = ['Peanuts', 'Dairy', 'Gluten', 'Shellfish', 'Eggs', 'Soy'];
  static const _skills = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Avatar
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(Icons.person_rounded, color: AppColors.primary, size: 52),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,
          const AppTextField(
            label: 'Full name',
            hint: 'Mark Khan',
            icon: Icons.person_outline_rounded,
          ),
          AppSpacing.vGapLg,
          const AppTextField(
            label: 'Email',
            hint: 'markikhan104@gmail.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          AppSpacing.vGapXl,
          Text('Dietary preferences', style: text.titleMedium),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: MockData.dietFilters.map((d) {
              final selected = _selectedDiet.contains(d);
              return FilterChip(
                label: Text(d),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                  selected ? _selectedDiet.remove(d) : _selectedDiet.add(d);
                }),
                labelStyle: text.labelMedium?.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
          AppSpacing.vGapXl,
          Text('Allergies', style: text.titleMedium),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _allergies.map((a) {
              final selected = _selectedAllergies.contains(a);
              return FilterChip(
                label: Text(a),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.coral,
                onSelected: (_) => setState(() {
                  selected ? _selectedAllergies.remove(a) : _selectedAllergies.add(a);
                }),
                labelStyle: text.labelMedium?.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
          AppSpacing.vGapXl,
          Text('Cooking skill', style: text.titleMedium),
          AppSpacing.vGapSm,
          Row(
            children: _skills.map((s) {
              final selected = s == _skill;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(() => _skill = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Theme.of(context).colorScheme.surface,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(
                          color: selected ? AppColors.primary : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Text(s,
                          style: text.labelMedium?.copyWith(
                            color: selected ? Colors.white : AppColors.textSecondary,
                          )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          AppSpacing.vGapXl,
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated ✓')),
              );
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}
