import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ─── Orange Glow Progress Ring ──────────────────────────
class GlowRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? child;
  final List<Color>? gradientColors;

  const GlowRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8,
    this.color,
    this.child,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GlowRingPainter(
              progress: progress,
              color: color ?? AppColors.primary,
              strokeWidth: strokeWidth,
              gradientColors: gradientColors,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final List<Color>? gradientColors;

  _GlowRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (gradientColors != null && gradientColors!.length >= 2) {
      progressPaint.shader = SweepGradient(
        startAngle: -1.5708,
        endAngle: -1.5708 + (6.2832 * progress),
        colors: gradientColors!,
      ).createShader(rect);
    } else {
      progressPaint.color = color;
      // Add glow
      canvas.drawArc(rect, -1.5708, 6.2832 * progress, false,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    canvas.drawArc(rect, -1.5708, 6.2832 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Orange Stat Ring with label ────────────────────────
class StatRing extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double progress;
  final Color color;
  final IconData icon;

  const StatRing({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlowRing(
          progress: progress,
          size: 70,
          strokeWidth: 6,
          color: color,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 1),
              Text(value, style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12,
              )),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        Text(unit, style: AppTextStyles.label),
      ],
    );
  }
}

// ─── GoFaster Card ───────────────────────────────────────
class GFCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final bool glow;
  final Color? color;
  final VoidCallback? onTap;

  const GFCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.glow = false,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: cardDecoration(radius: radius, color: color, hasGlow: glow),
        child: child,
      ),
    );
  }
}

// ─── Primary Button ──────────────────────────────────────
class GFPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool fullWidth;
  final double height;
  final bool loading;

  const GFPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.fullWidth = true,
    this.height = 56,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap?.call();
            },
      child: Container(
        height: height,
        width: fullWidth ? double.infinity : null,
        padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: AppGradients.fire,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.40),
              blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: loading
            ? const Center(child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              ))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppTextStyles.button),
                ],
              ),
      ),
    );
  }
}

// ─── Outlined Button ─────────────────────────────────────
class GFOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const GFOutlineButton({super.key, required this.label, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTextStyles.button.copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

// ─── Orange Tag / Chip ────────────────────────────────────
class GFTag extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final bool filled;

  const GFTag({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? bg.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: bg.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.tag.copyWith(
          color: textColor ?? bg,
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h4),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

// ─── Metric Tile ─────────────────────────────────────────
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GFCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.h3.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}

// ─── GoFaster Score Badge ────────────────────────────────
class ScoreBadge extends StatelessWidget {
  final double score;
  final double delta;
  final double size;

  const ScoreBadge({super.key, required this.score, required this.delta, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return GlowRing(
      progress: score / 100,
      size: size,
      strokeWidth: 10,
      gradientColors: const [AppColors.primary, AppColors.accent],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_rounded, color: AppColors.primary, size: 22),
          Text(
            score.toInt().toString(),
            style: AppTextStyles.h1.copyWith(fontSize: 38, height: 1.0),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${delta.toInt()}%',
              style: AppTextStyles.label.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Banner ─────────────────────────────────────────
class InfoBanner extends StatelessWidget {
  final String message;
  final Color? color;
  final IconData icon;
  final VoidCallback? onTap;

  const InfoBanner({
    super.key,
    required this.message,
    this.color,
    this.icon = Icons.bolt_rounded,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary)),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded, color: c, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Add Button ────────────────────────────────────
class QuickAddBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;

  const QuickAddBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: active ? AppGradients.fire : null,
          color: active ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: active ? Colors.transparent : AppColors.border,
            width: 1,
          ),
          boxShadow: active
              ? [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12, spreadRadius: -2,
                )]
              : null,
        ),
        child: Text(label, style: AppTextStyles.buttonSm.copyWith(
          color: active ? Colors.white : AppColors.textSecondary,
        )),
      ),
    );
  }
}

// ─── Loading Skeleton ─────────────────────────────────────
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: _anim.value + 0.3),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ─── Error Boundary Card ─────────────────────────────────
class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorCard({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodySm.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text('Try Again', style: AppTextStyles.buttonSm.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Ripple Button ────────────────────────────────────────
// Wraps any widget with Material ink ripple for tactile feedback
class RippleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Color? splashColor;

  const RippleBtn({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 16,
    this.splashColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: (splashColor ?? AppColors.primary).withValues(alpha: 0.15),
        highlightColor: (splashColor ?? AppColors.primary).withValues(alpha: 0.08),
        child: child,
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.h4, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.bodySm.copyWith(height: 1.6), textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              GFPrimaryButton(
                label: actionLabel!,
                onTap: onAction,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Fade Route (300ms FadeTransition for all navigation) ───────────────────
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

// ─── Orange Circular Loading Indicator ──────────────────────────────────────
class OrangeLoader extends StatelessWidget {
  final double size;
  const OrangeLoader({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 3,
      ),
    );
  }
}

// ─── Network Error Widget ───────────────────────────────────────────────────
class NetworkError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const NetworkError({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.error, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Connection Error',
                style: AppTextStyles.h4, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GFPrimaryButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onTap: onRetry,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
