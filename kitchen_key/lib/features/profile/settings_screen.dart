import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('APPEARANCE', style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.vGapSm,
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.brMd,
            ),
            child: Column(
              children: [
                _themeOption(context, ref, 'System default', Icons.brightness_auto_rounded, ThemeMode.system, mode),
                _themeOption(context, ref, 'Light', Icons.light_mode_rounded, ThemeMode.light, mode),
                _themeOption(context, ref, 'Dark', Icons.dark_mode_rounded, ThemeMode.dark, mode),
              ],
            ),
          ),
          AppSpacing.vGapXl,
          Text('NOTIFICATIONS', style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.vGapSm,
          _switchTile(context, Icons.recommend_rounded, 'Recipe recommendations', true),
          _switchTile(context, Icons.calendar_today_rounded, 'Meal plan reminders', true),
          _switchTile(context, Icons.water_drop_rounded, 'Hydration reminders', true),
          _switchTile(context, Icons.local_offer_rounded, 'New recipes & offers', false),
          AppSpacing.vGapXl,
          Text('GENERAL', style: text.labelSmall?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.vGapSm,
          _linkTile(context, Icons.straighten_rounded, 'Units', 'Metric'),
          _linkTile(context, Icons.language_rounded, 'Language', 'English'),
          _linkTile(context, Icons.lock_outline_rounded, 'Privacy & Security', null),
          _linkTile(context, Icons.info_outline_rounded, 'About Kitchen Key', 'v1.0.0'),
          AppSpacing.vGapXl,
          Center(
            child: Text('Made with 🍳 for your kitchen',
                style: text.bodySmall?.copyWith(color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext context, WidgetRef ref, String label, IconData icon,
      ThemeMode value, ThemeMode current) {
    final selected = value == current;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brSm,
        onTap: () => ref.read(themeModeProvider.notifier).set(value),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
              AppSpacing.hGapMd,
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchTile(BuildContext context, IconData icon, String title, bool initial) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _Tile(
        icon: icon,
        title: title,
        trailing: _ToggleSwitch(initial: initial),
      ),
    );
  }

  Widget _linkTile(BuildContext context, IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _Tile(
        icon: icon,
        title: title,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  const _Tile({required this.icon, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          AppSpacing.hGapMd,
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleSwitch extends StatefulWidget {
  final bool initial;
  const _ToggleSwitch({required this.initial});

  @override
  State<_ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<_ToggleSwitch> {
  late bool _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      activeThumbColor: AppColors.primary,
    );
  }
}
