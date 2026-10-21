import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';

class _OnboardingStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;

  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _current = 0;

  static const _steps = [
    _OnboardingStep(
      title: 'Une idée ?',
      subtitle: 'NabuProjet IA vous aide à la transformer en projet.',
      icon: Icons.lightbulb_outline,
      gradientColors: [NabuColors.violet, NabuColors.electricBlue],
    ),
    _OnboardingStep(
      title: 'Un plan clair',
      subtitle: 'Objectifs, étapes, tâches et planning.',
      icon: Icons.map_outlined,
      gradientColors: [NabuColors.electricBlue, NabuColors.cyan],
    ),
    _OnboardingStep(
      title: 'Un chef de projet IA',
      subtitle: 'Discutez avec lui lorsque vous avez besoin d\'aide.',
      icon: Icons.auto_awesome,
      gradientColors: [NabuColors.cyan, NabuColors.turquoise],
    ),
    _OnboardingStep(
      title: 'Votre projet évolue',
      subtitle: 'L\'IA adapte le plan lorsque la situation change.',
      icon: Icons.sync,
      gradientColors: [NabuColors.magenta, NabuColors.violet],
    ),
    _OnboardingStep(
      title: 'Passez à l\'action',
      subtitle: 'Toujours savoir quelle est la prochaine étape.',
      icon: Icons.rocket_launch,
      gradientColors: [NabuColors.violet, NabuColors.magenta],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() async {
    ref.read(databaseProvider).setOnboardingDone();
    if (mounted) {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        nav.popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return _buildStep(step, isDark);
                  },
                ),
              ),
              _buildDots(isDark),
              const SizedBox(height: 16),
              _buildBottom(isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(_OnboardingStep step, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: step.gradientColors
                    .map((c) => c.withValues(alpha: isDark ? 0.25 : 0.15))
                    .toList(),
              ),
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: step.gradientColors,
                  ),
                ),
                child: Icon(step.icon, size: 44, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1233),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            step.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length, (i) {
        final active = i == _current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? _steps[i].gradientColors.first
                : (isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBottom(bool isDark) {
    final isLast = _current == _steps.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: isLast
          ? GradientButton(
              label: 'CRÉER MON PREMIER PROJET',
              icon: Icons.rocket_launch,
              onPressed: _finish,
              expanded: true,
            )
          : Row(
              children: [
                Expanded(
                  child: GradientButton(
                    label: 'Suivant',
                    icon: Icons.arrow_forward,
                    onPressed: _next,
                    expanded: true,
                  ),
                ),
              ],
            ),
    );
  }
}
