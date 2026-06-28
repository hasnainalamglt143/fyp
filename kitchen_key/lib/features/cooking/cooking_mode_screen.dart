import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/recipe.dart';

/// Full-screen, distraction-free cooking guide: one step per page, large text,
/// a countdown timer, and text-to-speech "read aloud". Keeps the screen awake.
class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  final _pageController = PageController();
  final FlutterTts _tts = FlutterTts();
  int _index = 0;

  // Timer state
  Timer? _timer;
  int _secondsLeft = 0;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _steps => widget.recipe.steps;

  Future<void> _readAloud() async {
    await _tts.stop();
    await _tts.setSpeechRate(0.45);
    await _tts.speak(_steps[_index]);
  }

  void _startTimer(int minutes) {
    _timer?.cancel();
    setState(() {
      _secondsLeft = minutes * 60;
      _timerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() {
          _secondsLeft = 0;
          _timerRunning = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⏰ Timer finished!')),
          );
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _toggleTimer() {
    if (_timerRunning) {
      _timer?.cancel();
      setState(() => _timerRunning = false);
    } else if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft <= 1) {
          t.cancel();
          setState(() {
            _secondsLeft = 0;
            _timerRunning = false;
          });
        } else {
          setState(() => _secondsLeft--);
        }
      });
      setState(() => _timerRunning = true);
    }
  }

  String get _timeLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _next() {
    if (_index < _steps.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded, color: AppColors.primary, size: 48),
        title: const Text('Bon appétit!'),
        content: const Text('You finished cooking. Enjoy your meal! 🍽️',
            textAlign: TextAlign.center),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final progress = (_index + 1) / _steps.length;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      widget.recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: text.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.brPill,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Step ${_index + 1} of ${_steps.length}',
                      style: text.labelMedium?.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            // Steps
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _tts.stop();
                },
                itemCount: _steps.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${i + 1}',
                                style: text.displayLarge?.copyWith(
                                    color: AppColors.primary.withValues(alpha: 0.18),
                                    fontSize: 90)),
                            Text(_steps[i],
                                style: text.headlineMedium?.copyWith(height: 1.4)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Timer
            if (_secondsLeft > 0 || _timerRunning)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: AppRadius.brMd,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: AppColors.accentDark),
                    AppSpacing.hGapMd,
                    Text(_timeLabel,
                        style: text.headlineSmall?.copyWith(color: AppColors.accentDark)),
                    const Spacer(),
                    IconButton(
                      onPressed: _toggleTimer,
                      icon: Icon(_timerRunning
                          ? Icons.pause_circle_rounded
                          : Icons.play_circle_rounded,
                          color: AppColors.accentDark),
                    ),
                  ],
                ),
              ),
            // Controls
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  _circleAction(Icons.timer_outlined, 'Timer', () => _showTimerSheet()),
                  AppSpacing.hGapMd,
                  _circleAction(Icons.volume_up_rounded, 'Read', _readAloud),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_index == _steps.length - 1 ? 'Finish' : 'Next step'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleAction(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0)),
      ],
    );
  }

  void _showTimerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set a timer', style: Theme.of(ctx).textTheme.titleLarge),
            AppSpacing.vGapLg,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [1, 3, 5, 10, 15, 20, 30, 45].map((m) {
                return ActionChip(
                  label: Text('$m min'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startTimer(m);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
