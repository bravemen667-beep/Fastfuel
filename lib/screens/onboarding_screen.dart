import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      title: 'Track Every\nRepeat.',
      subtitle: 'Your body, your rules. Monitor water, calories, sleep and vitamins — all in one shot.',
      icon: Icons.bolt_rounded,
      step: 'Fuel your performance',
    ),
    _OnboardPage(
      title: 'Hit Goals\nFaster.',
      subtitle: 'Set daily targets. AI-powered insights push you harder every single session.',
      icon: Icons.track_changes_rounded,
      step: 'Smart daily goals',
    ),
    _OnboardPage(
      title: 'No Excuses.\nJust Results.',
      subtitle: 'Streaks, reminders, and real-time scores keep you accountable 24/7.',
      icon: Icons.emoji_events_rounded,
      step: 'Stay consistent',
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToApp();
    }
  }

  void _goToApp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow orbs
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100, left: -80,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              gradient: AppGradients.fire,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Text('GoFaster', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                        ],
                      ),
                      if (_page < _pages.length - 1)
                        GestureDetector(
                          onTap: _goToApp,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text('Skip', style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            )),
                          ),
                        ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) => _PageContent(
                      page: _pages[index],
                      pageIndex: index,
                      screenSize: size,
                    ),
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      SmoothPageIndicator(
                        controller: _controller,
                        count: _pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: AppColors.primary,
                          dotColor: AppColors.border,
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 4,
                          spacing: 6,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GFPrimaryButton(
                        label: _page == _pages.length - 1 ? 'Start Going Faster' : 'Continue',
                        icon: _page == _pages.length - 1
                            ? Icons.bolt_rounded
                            : Icons.arrow_forward_rounded,
                        onTap: _next,
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

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  final int pageIndex;
  final Size screenSize;

  const _PageContent({
    required this.page,
    required this.pageIndex,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero icon card
          Container(
            width: screenSize.width * 0.65,
            height: screenSize.width * 0.65,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  blurRadius: 40, spreadRadius: -5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Concentric rings
                ...List.generate(3, (i) => Container(
                  width: (screenSize.width * 0.25) + (i * 45.0),
                  height: (screenSize.width * 0.25) + (i * 45.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.10 - (i * 0.025)),
                      width: 1,
                    ),
                  ),
                )),
                // Icon
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    gradient: AppGradients.fire,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 30, spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Icon(page.icon, color: Colors.white, size: 46),
                ),
                // Stats decorators
                Positioned(
                  top: 25, right: 25,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 14),
                        const SizedBox(width: 4),
                        Text('88', style: AppTextStyles.caption.copyWith(
                          color: AppColors.success, fontWeight: FontWeight.w700,
                        )),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 25, left: 25,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppGradients.fire,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text('GO FASTER', style: AppTextStyles.label.copyWith(
                      color: Colors.white,
                    )),
                  ),
                ),
              ],
            ),
          ).animate().scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1.0, 1.0),
            duration: 500.ms,
            curve: Curves.easeOutBack,
          ).fade(duration: 400.ms),

          const SizedBox(height: 40),

          // Step label
          GFTag(label: page.step, color: AppColors.primary)
              .animate(delay: 200.ms)
              .fade(duration: 400.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 16),

          // Title
          Text(
            page.title,
            style: AppTextStyles.h1,
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fade(duration: 400.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 14),

          // Subtitle
          Text(
            page.subtitle,
            style: AppTextStyles.bodySm.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ).animate(delay: 400.ms).fade(duration: 400.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final String step;
  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.step,
  });
}
