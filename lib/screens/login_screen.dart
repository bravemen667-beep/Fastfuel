import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _phoneValid = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(() {
      final val = _phoneCtrl.text.replaceAll(' ', '');
      setState(() => _phoneValid = val.length == 10);
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // ── Send OTP ─────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!_phoneValid) return;
    final phone = _phoneCtrl.text.trim();
    final auth = context.read<AuthProvider>();

    final ok = await auth.sendOtp(phone);
    if (!mounted) return;

    if (ok) {
      Navigator.push(
        context,
        _slideRoute(OtpScreen(phone: phone)),
      );
    } else {
      _showError('Could not send OTP. Please try again.');
    }
  }

  // ── Google Sign-In ──────────────────────────────────
  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
    if (!mounted) return;

    if (ok) {
      _goToHome();
    } else {
      _showGoogleSignInError();
    }
  }

  void _showGoogleSignInError() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.g_mobiledata_rounded, color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Sign In Failed', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Text(
                'Sign in failed. Please try again.\n\nIf the issue persists, ensure your device has an active internet connection and Google Play Services are up to date.',
                style: AppTextStyles.bodySm.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel',
                        style: AppTextStyles.button.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _googleSignIn();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        elevation: 0,
                      ),
                      child: Text('Retry', style: AppTextStyles.button),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Guest ────────────────────────────────────────────
  Future<void> _guestLogin() async {
    await context.read<AuthProvider>().continueAsGuest();
    if (!mounted) return;
    _goToHome();
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (_) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: AppTextStyles.bodySm.copyWith(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.cardBg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Gradient orbs ─────────────────────────────
          Positioned(
            top: -60, right: -60,
            child: _GlowOrb(color: AppColors.primary, size: 240),
          ),
          Positioned(
            top: size.height * 0.25, left: -80,
            child: _GlowOrb(color: AppColors.accent, size: 180),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // ── Brand Header ──────────────────
                      _BrandHeader()
                          .animate()
                          .fade(duration: 600.ms)
                          .slideY(begin: -0.3, end: 0, curve: Curves.easeOutCubic),

                      const SizedBox(height: 48),

                      // ── Headline ──────────────────────
                      Text(
                        'Welcome to\nGoFaster! 🔥',
                        style: AppTextStyles.h1.copyWith(height: 1.2),
                      ).animate(delay: 150.ms).fade(duration: 500.ms).slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 8),

                      Text(
                        'India\'s #1 health performance tracker.\nLog in to start going faster.',
                        style: AppTextStyles.bodySm.copyWith(height: 1.6),
                      ).animate(delay: 200.ms).fade(duration: 500.ms),

                      const SizedBox(height: 36),

                      // ── Phone Input ───────────────────
                      _PhoneInputSection(
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        isValid: _phoneValid,
                        isLoading: auth.isLoading,
                        onSend: _sendOtp,
                      ).animate(delay: 300.ms).fade(duration: 500.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 24),

                      // ── Divider ───────────────────────
                      _OrDivider().animate(delay: 350.ms).fade(duration: 400.ms),

                      const SizedBox(height: 24),

                      // ── Google Sign-In ────────────────
                      _GoogleButton(
                        isLoading: auth.isLoading,
                        onTap: _googleSignIn,
                      ).animate(delay: 400.ms).fade(duration: 500.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      // ── Guest ─────────────────────────
                      _GuestButton(
                        onTap: _guestLogin,
                      ).animate(delay: 450.ms).fade(duration: 500.ms),

                      const SizedBox(height: 36),

                      // ── Terms ─────────────────────────
                      _TermsText().animate(delay: 500.ms).fade(duration: 400.ms),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 380),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}

// ─── Brand Header ────────────────────────────────────────
class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: AppGradients.fire,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16, spreadRadius: -4,
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GoFaster', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
            Text('Health & Performance', style: AppTextStyles.label),
          ],
        ),
      ],
    );
  }
}

// ─── Phone Input Section ─────────────────────────────────
class _PhoneInputSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isValid;
  final bool isLoading;
  final VoidCallback onSend;

  const _PhoneInputSection({
    required this.controller,
    required this.focusNode,
    required this.isValid,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mobile Number', style: AppTextStyles.h5),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isValid ? AppColors.primary : AppColors.border,
              width: isValid ? 1.5 : 1,
            ),
            boxShadow: isValid
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 12)]
                : null,
          ),
          child: Row(
            children: [
              // Country prefix
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Text('🇮🇳', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text('+91', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 16),
                  ],
                ),
              ),
              // Input
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '9876 543 210',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.textDisabled, letterSpacing: 1,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
              ),
              // Check icon
              if (isValid)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22)
                      .animate().scale(duration: 200.ms, curve: Curves.elasticOut),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Send OTP Button
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: isValid ? AppGradients.fire : null,
            color: isValid ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isValid
                ? [BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 6),
                  )]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (isValid && !isLoading) ? onSend : null,
              borderRadius: BorderRadius.circular(50),
              splashColor: Colors.white.withValues(alpha: 0.2),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Send OTP',
                            style: AppTextStyles.button.copyWith(
                              color: isValid ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                          if (isValid) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── OR Divider ──────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or', style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
        ),
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}

// ─── Google Button ────────────────────────────────────────
class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(50),
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoogleIcon(),
                      const SizedBox(width: 12),
                      Text('Continue with Google', style: AppTextStyles.button.copyWith(
                        color: AppColors.textPrimary,
                      )),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

// ─── Guest Button ─────────────────────────────────────────
class _GuestButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GuestButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 16),
            const SizedBox(width: 6),
            Text(
              'Continue as Guest',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textMuted,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Terms ───────────────────────────────────────────────
class _TermsText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.label.copyWith(height: 1.6),
          children: [
            const TextSpan(text: 'By continuing, you agree to GoFaster\'s\n'),
            TextSpan(
              text: 'Terms of Service',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: ' & '),
            TextSpan(
              text: 'Privacy Policy',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glow Orb ────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
