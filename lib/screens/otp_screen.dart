import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength     = 6;
  static const int _timerSeconds  = 60; // 60-second countdown per spec

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  int     _secondsLeft = _timerSeconds;
  Timer?  _timer;
  bool    _verifying   = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes)  { f.dispose(); }
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _timerSeconds;
      _errorMsg    = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  // ── OTP Input ─────────────────────────────────────────────────────────────
  void _onOtpInput(String val, int index) {
    setState(() => _errorMsg = null);
    if (val.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verify();
      }
    }
  }

  void _onKeyDown(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  // ── Verify ────────────────────────────────────────────────────────────────
  Future<void> _verify() async {
    final auth = context.read<GFAuthProvider>();

    // Client-side guard: blocked after 3 wrong attempts
    if (auth.otpBlocked) {
      setState(() => _errorMsg = 'Too many attempts. Please request a new OTP.');
      return;
    }

    final otp = _otpValue;

    // Client-side: must be exactly 6 digits before calling Firebase
    if (otp.length < _otpLength) {
      setState(() => _errorMsg = 'Please enter all $_otpLength digits.');
      return;
    }

    setState(() {
      _verifying = true;
      _errorMsg  = null;
    });

    try {
      final ok = await auth.loginWithPhone(
        phone: widget.phone,
        otp:   otp,
      );

      if (!mounted) return;

      if (ok) {
        // FirebaseAuth stream in _AuthGate will handle routing automatically.
        // Pop back to login so the stream rebuild replaces the entire stack.
        Navigator.popUntil(context, (r) => r.isFirst);
      } else {
        final errMsg = auth.errorMessage ?? 'Invalid OTP. Please try again.';
        setState(() {
          _verifying = false;
          _errorMsg  = errMsg;
        });
        // Clear boxes + refocus for next attempt
        for (final c in _controllers) { c.clear(); }
        _focusNodes[0].requestFocus();
      }
    } on OtpBlockedException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _errorMsg  = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _errorMsg  = 'Verification failed. Please try again.';
      });
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;
    final auth = context.read<GFAuthProvider>();
    final ok = await auth.sendOtp(widget.phone);
    if (!mounted) return;
    if (ok) {
      _startTimer();
      // Reset attempt counter on fresh OTP
      _showSnack('New OTP sent to +91 ${widget.phone}');
    } else {
      final msg = auth.errorMessage ?? 'Could not send OTP. Please try again.';
      setState(() => _errorMsg = msg);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTextStyles.bodySm),
        backgroundColor: AppColors.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<GFAuthProvider>();
    final blocked = auth.otpBlocked;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 16,
                      ),
                    ),
                  ).animate().fade(duration: 400.ms),

                  const SizedBox(height: 32),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: AppGradients.fire,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verify OTP', style: AppTextStyles.h3),
                          Text('Sent via SMS', style: AppTextStyles.bodySm),
                        ],
                      ),
                    ],
                  ).animate(delay: 100.ms).fade(duration: 500.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 20),

                  // Phone info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '+91 ${_formatPhone(widget.phone)}',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Change',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 150.ms).fade(duration: 400.ms),

                  const SizedBox(height: 36),

                  Text('Enter 6-digit OTP', style: AppTextStyles.h4)
                      .animate(delay: 200.ms).fade(duration: 400.ms),
                  const SizedBox(height: 6),
                  Text(
                    'We sent a verification code to your number. It expires in 10 minutes.',
                    style: AppTextStyles.bodySm,
                  ).animate(delay: 220.ms).fade(duration: 400.ms),

                  const SizedBox(height: 28),

                  // OTP Boxes
                  _OtpBoxes(
                    controllers: _controllers,
                    focusNodes:  _focusNodes,
                    onInput:     _onOtpInput,
                    onKeyDown:   _onKeyDown,
                    hasError:    _errorMsg != null,
                    disabled:    blocked,
                  ).animate(delay: 300.ms).fade(duration: 500.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 14),

                  // Error / Blocked message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _errorMsg != null
                        ? Padding(
                            key: const ValueKey('err'),
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.error_rounded, color: AppColors.error, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(_errorMsg!, style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.error,
                                  )),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-err')),
                  ),

                  // Attempt counter
                  if (auth.otpAttempts > 0 && !blocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${GFAuthProvider.maxOtpAttempts - auth.otpAttempts} attempt${GFAuthProvider.maxOtpAttempts - auth.otpAttempts == 1 ? "" : "s"} remaining',
                        style: AppTextStyles.label.copyWith(color: AppColors.warning),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Verify Button (disabled when blocked)
                  _VerifyButton(
                    otp:       _otpValue,
                    otpLength: _otpLength,
                    verifying: _verifying,
                    disabled:  blocked,
                    onVerify:  _verify,
                  ).animate(delay: 350.ms).fade(duration: 500.ms),

                  const SizedBox(height: 28),

                  // Resend
                  _ResendSection(
                    secondsLeft: _secondsLeft,
                    onResend:    _resendOtp,
                    isLoading:   auth.isLoading,
                  ).animate(delay: 400.ms).fade(duration: 400.ms),

                  const Spacer(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhone(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phone;
  }
}

// ─── OTP Box Row ──────────────────────────────────────────────────────────────
class _OtpBoxes extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode>             focusNodes;
  final Function(String, int)       onInput;
  final Function(KeyEvent, int)     onKeyDown;
  final bool hasError;
  final bool disabled;

  const _OtpBoxes({
    required this.controllers,
    required this.focusNodes,
    required this.onInput,
    required this.onKeyDown,
    required this.hasError,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (i) {
        return _OtpBox(
          controller: controllers[i],
          focusNode:  focusNodes[i],
          onChanged:  (v) => onInput(v, i),
          onKeyEvent: (e) => onKeyDown(e, i),
          hasError:   hasError,
          disabled:   disabled,
        );
      }),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final ValueChanged<String>  onChanged;
  final Function(KeyEvent)    onKeyEvent;
  final bool hasError;
  final bool disabled;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
    required this.hasError,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, val, __) {
          final filled = val.text.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48, height: 58,
            decoration: BoxDecoration(
              color: disabled
                  ? AppColors.surface
                  : hasError
                      ? AppColors.error.withValues(alpha: 0.08)
                      : filled
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: disabled
                    ? AppColors.border
                    : hasError
                        ? AppColors.error
                        : filled
                            ? AppColors.primary
                            : focusNode.hasFocus
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : AppColors.border,
                width: filled || focusNode.hasFocus ? 2 : 1,
              ),
              boxShadow: filled && !disabled
                  ? [BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                    )]
                  : null,
            ),
            child: Center(
              child: TextField(
                controller: controller,
                focusNode:  focusNode,
                keyboardType: TextInputType.number,
                textAlign:    TextAlign.center,
                maxLength:    1,
                enabled:      !disabled,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.h3.copyWith(
                  color: disabled
                      ? AppColors.textMuted
                      : hasError
                          ? AppColors.error
                          : AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  border:        InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText:   '',
                  isDense:       true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: onChanged,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Verify Button ────────────────────────────────────────────────────────────
class _VerifyButton extends StatelessWidget {
  final String       otp;
  final int          otpLength;
  final bool         verifying;
  final bool         disabled;
  final VoidCallback onVerify;

  const _VerifyButton({
    required this.otp,
    required this.otpLength,
    required this.verifying,
    required this.disabled,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final ready = otp.length == otpLength && !disabled;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: ready ? AppGradients.fire : null,
        color:    ready ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(50),
        boxShadow: ready
            ? [BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 6),
              )]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (ready && !verifying) ? onVerify : null,
          borderRadius: BorderRadius.circular(50),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Center(
            child: verifying
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Verifying...', style: AppTextStyles.button),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        disabled
                            ? Icons.lock_rounded
                            : Icons.verified_user_rounded,
                        color: ready ? Colors.white : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        disabled ? 'Request New OTP' : 'Verify & Login',
                        style: AppTextStyles.button.copyWith(
                          color: ready ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Resend Section ───────────────────────────────────────────────────────────
class _ResendSection extends StatelessWidget {
  final int          secondsLeft;
  final VoidCallback onResend;
  final bool         isLoading;

  const _ResendSection({
    required this.secondsLeft,
    required this.onResend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final canResend = secondsLeft == 0 && !isLoading;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Didn't receive OTP? ",
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          GestureDetector(
            onTap: canResend ? onResend : null,
            child: canResend
                ? Text(
                    'Resend OTP',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700,
                    ),
                  )
                : Row(
                    children: [
                      const Icon(Icons.timer_rounded, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Resend in ${secondsLeft}s',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
