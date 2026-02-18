import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardPage(
      title: 'Fuel Your\nPerformance',
      subtitle: 'Science-backed hydration, nutrition & sleep insights — all in one place.',
      icon: Icons.bolt_rounded,
      accentColor: AppColors.primary,
      features: const [
        _Feature(Icons.water_drop_rounded, 'Smart Hydration Tracking'),
        _Feature(Icons.local_fire_department_rounded, 'Calorie & Macro Goals'),
        _Feature(Icons.bedtime_rounded, 'Sleep Quality Analysis'),
      ],
    ),
    _OnboardPage(
      title: 'AI-Powered\nWorkout Plans',
      subtitle: 'Your GoFaster Score adapts daily workouts to your recovery & energy levels.',
      icon: Icons.fitness_center_rounded,
      accentColor: AppColors.neonBlue,
      features: const [
        _Feature(Icons.auto_awesome_rounded, 'AI Workout Recommendations'),
        _Feature(Icons.monitor_heart_rounded, 'HRV & Recovery Alerts'),
        _Feature(Icons.trending_up_rounded, 'Performance Scoring'),
      ],
    ),
    _OnboardPage(
      title: 'Daily Vitamin\nProtocol',
      subtitle: 'Track your GoFaster supplement stack and never miss a dose again.',
      icon: Icons.medication_rounded,
      accentColor: AppColors.neonGreen,
      features: const [
        _Feature(Icons.medication_liquid_rounded, 'Vitamin Intake Logging'),
        _Feature(Icons.notifications_active_rounded, 'Smart Reminders'),
        _Feature(Icons.inventory_2_rounded, 'Stock Alerts & Reorder'),
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _launchApp();
    }
  }

  void _launchApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Ambient background glow ──────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: SizedBox(
              key: ValueKey(_currentPage),
              width: size.width,
              height: size.height,
              child: Stack(children: [
                GlowBlob(
                  color: _pages[_currentPage].accentColor,
                  size: size.width * 1.4,
                  alignment: const Alignment(0, -0.4),
                  opacity: 0.12,
                ),
                GlowBlob(
                  color: _pages[_currentPage].accentColor,
                  size: size.width * 0.8,
                  alignment: const Alignment(0.8, 0.8),
                  opacity: 0.08,
                ),
              ]),
            ),
          ),

          // ── Floating orb bubbles ─────────────────────
          const _FloatingBubbles(),

          SafeArea(
            child: Column(
              children: [
                // ── Skip button ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: AppGradients.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Text('GoFaster', style: AppTextStyles.headingSm.copyWith(
                            color: Colors.white,
                            fontSize: 17,
                          )),
                        ],
                      ).animate().fadeIn(duration: 600.ms),
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: _launchApp,
                          child: Text('Skip',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            )),
                        ).animate().fadeIn(duration: 600.ms),
                    ],
                  ),
                ),

                // ── Page content ─────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _pages[i],
                  ),
                ),

                // ── Bottom controls ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Column(
                    children: [
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: _pages[_currentPage].accentColor,
                          dotColor: Colors.white.withValues(alpha: 0.15),
                          dotHeight: 6,
                          dotWidth: 6,
                          expansionFactor: 4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GradientButton(
                        label: _currentPage < _pages.length - 1
                            ? 'Continue'
                            : 'Start Your Journey',
                        icon: _currentPage < _pages.length - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.rocket_launch_rounded,
                        gradient: LinearGradient(
                          colors: [
                            _pages[_currentPage].accentColor,
                            AppColors.primary,
                          ],
                        ),
                        onPressed: _nextPage,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                      const SizedBox(height: 16),
                      Text(
                        'By continuing you agree to our Terms of Service',
                        style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single Onboarding Page ───────────────────────────
class _OnboardPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<_Feature> features;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withValues(alpha: 0.3), accentColor.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 42),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 32),

          Text(title,
            style: AppTextStyles.headingXL.copyWith(
              fontSize: 36,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),

          const SizedBox(height: 14),

          Text(subtitle,
            style: AppTextStyles.body.copyWith(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

          const SizedBox(height: 36),

          // Feature list
          ...features.asMap().entries.map((e) {
            final delay = (e.key * 100 + 200).ms;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                    ),
                    child: Icon(e.value.icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(e.value.label,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
                  ),
                ],
              ).animate().fadeIn(delay: delay, duration: 400.ms).slideX(begin: 0.15),
            );
          }),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
}

// ── Floating decorative bubbles ──────────────────────
class _FloatingBubbles extends StatefulWidget {
  const _FloatingBubbles();

  @override
  State<_FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<_FloatingBubbles>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  final _bubbles = [
    _Bubble(0.15, 0.22, 14, AppColors.primary, 0.4),
    _Bubble(0.80, 0.35, 20, AppColors.neonBlue, 0.3),
    _Bubble(0.25, 0.50, 10, AppColors.primary, 0.5),
    _Bubble(0.90, 0.15, 8, Colors.white, 0.15),
    _Bubble(0.65, 0.72, 16, AppColors.primary, 0.25),
    _Bubble(0.10, 0.68, 12, AppColors.neonGreen, 0.2),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_bubbles.length, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1800 + i * 400),
      )..repeat(reverse: true);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: List.generate(_bubbles.length, (i) {
        final b = _bubbles[i];
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Positioned(
            left: size.width * b.x,
            top: size.height * b.y + (_controllers[i].value - 0.5) * 12,
            child: Container(
              width: b.size,
              height: b.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: b.color.withValues(alpha: b.opacity),
                boxShadow: [
                  BoxShadow(
                    color: b.color.withValues(alpha: b.opacity * 0.6),
                    blurRadius: b.size,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Bubble {
  final double x, y, size, opacity;
  final Color color;
  const _Bubble(this.x, this.y, this.size, this.color, this.opacity);
}
