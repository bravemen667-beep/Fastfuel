// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Share Progress Screen (Complete Rebuild)
//  FontAwesome brand icons · Real URL deep links · No paywall
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../providers/auth_provider.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────
class ShareProgressScreen extends StatelessWidget {
  const ShareProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hp   = context.watch<HealthProvider>();
    final auth = context.watch<GFAuthProvider>();
    final name = auth.userName.isEmpty ? 'Athlete' : auth.userName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _ShareCard(hp: hp, name: name)
                  .animate().fade(duration: 500.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              _SectionLabel('Share on Social').animate(delay: 100.ms).fade(),
              const SizedBox(height: 14),
              _SocialGrid(hp: hp, name: name)
                  .animate(delay: 150.ms).fade(duration: 400.ms),
              const SizedBox(height: 24),
              _SectionLabel('Quick Actions').animate(delay: 200.ms).fade(),
              const SizedBox(height: 14),
              _QuickActions(hp: hp, name: name)
                  .animate(delay: 250.ms).fade(duration: 400.ms),
            ])),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: AppColors.background,
      expandedHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
      collapsedHeight: kToolbarHeight,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Share Progress', style: AppTextStyles.h3),
                Text('Show off your GoFaster journey',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            )),
          ]),
        ),
      ),
    );
  }
}

// ─── Share Card Preview ───────────────────────────────────────────────────────
class _ShareCard extends StatelessWidget {
  final HealthProvider hp;
  final String name;
  const _ShareCard({required this.hp, required this.name});

  @override
  Widget build(BuildContext context) {
    final score = hp.score.toInt();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.2),
          blurRadius: 30, spreadRadius: -5, offset: const Offset(0, 10),
        )],
      ),
      child: Column(children: [
        // Header
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.fire,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Text('GoFaster Health',
              style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
          const Spacer(),
          Text(DateTime.now().toString().substring(0, 10),
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 24),

        // Score ring
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hey $name 👋',
                  style: AppTextStyles.h4.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text('Check out my GoFaster Score!',
                  style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              _buildScoreBar('Hydration',  hp.waterProgress,  const Color(0xFF2196F3)),
              const SizedBox(height: 8),
              _buildScoreBar('Sleep',      hp.sleepProgress,  const Color(0xFF9C27B0)),
              const SizedBox(height: 8),
              _buildScoreBar('Nutrition',  hp.caloriesProgress, AppColors.primary),
              const SizedBox(height: 8),
              _buildScoreBar('Activity',   hp.stepsProgress,  const Color(0xFF66BB6A)),
            ],
          )),
          const SizedBox(width: 20),
          Column(children: [
            SizedBox(
              width: 100, height: 100,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  strokeWidth: 8,
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$score', style: const TextStyle(
                      color: AppColors.primary, fontSize: 28,
                      fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                  const Text('/100', style: TextStyle(
                      color: AppColors.textMuted, fontSize: 11,
                      fontFamily: 'Poppins')),
                ]),
              ]),
            ),
            const SizedBox(height: 8),
            const Text('GoFaster\nScore', textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary,
                    fontSize: 11, fontFamily: 'Poppins')),
          ]),
        ]),
        const SizedBox(height: 20),

        // CTA row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.link_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            const Text('gofaster.in',
                style: TextStyle(color: AppColors.primary,
                    fontWeight: FontWeight.w700, fontSize: 13,
                    fontFamily: 'Poppins')),
            const Spacer(),
            const Text('#GoFaster #StayActive',
                style: TextStyle(color: AppColors.textMuted,
                    fontSize: 11, fontFamily: 'Poppins')),
          ]),
        ),
      ]),
    );
  }

  Widget _buildScoreBar(String label, double progress, Color c) => Row(children: [
    SizedBox(width: 68,
        child: Text(label, style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Poppins'))),
    Expanded(child: ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation(c),
        minHeight: 6,
      ),
    )),
    const SizedBox(width: 8),
    Text('${(progress * 100).toInt()}%',
        style: TextStyle(color: c, fontSize: 10,
            fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
  ]);
}

// ─── Social Grid ──────────────────────────────────────────────────────────────
class _SocialGrid extends StatelessWidget {
  final HealthProvider hp;
  final String name;
  const _SocialGrid({required this.hp, required this.name});

  String get _message =>
      'I scored ${hp.score.toInt()}/100 on GoFaster Health today! 💪⚡\n'
      'Join me: https://gofaster.in #GoFaster #StayActive';

  Future<void> _launch(BuildContext context, String url,
      {String? fallbackUrl, String? copyMessage}) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) { /* try fallback */ }

    if (fallbackUrl != null) {
      final fallback = Uri.parse(fallbackUrl);
      try {
        if (await canLaunchUrl(fallback)) {
          await launchUrl(fallback, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) { /* show snack */ }
    }

    if (copyMessage != null && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: 'https://gofaster.in'));
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(copyMessage,
              style: const TextStyle(color: Colors.white)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final platforms = [
      _BrandPlatform(
        icon: FontAwesomeIcons.whatsapp,
        label: 'WhatsApp',
        color: const Color(0xFF25D366),
        onTap: () => _launch(context,
            'whatsapp://send?text=${Uri.encodeComponent(_message)}',
            fallbackUrl:
            'https://api.whatsapp.com/send?text=${Uri.encodeComponent(_message)}'),
      ),
      _BrandPlatform(
        icon: FontAwesomeIcons.instagram,
        label: 'Instagram',
        color: const Color(0xFFE1306C),
        onTap: () async {
          final msg       = _message;
          final messenger = ScaffoldMessenger.of(context);
          // ignore: use_build_context_synchronously
          final launchCtx = context;
          await Clipboard.setData(ClipboardData(text: msg));
          messenger.showSnackBar(SnackBar(
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: const Text(
              'Caption copied! Opening Instagram — paste in your Story.',
              style: TextStyle(color: Colors.white),
            ),
          ));
          // ignore: use_build_context_synchronously
          await _launch(launchCtx, 'instagram://app',
              fallbackUrl: 'https://instagram.com');
        },
      ),
      _BrandPlatform(
        icon: FontAwesomeIcons.snapchat,
        label: 'Snapchat',
        color: const Color(0xFFFFFC00),
        onTap: () => _launch(context, 'snapchat://',
            fallbackUrl: 'https://snapchat.com',
            copyMessage: 'Screenshot copied! Open Snapchat to share.'),
      ),
      _BrandPlatform(
        icon: FontAwesomeIcons.linkedin,
        label: 'LinkedIn',
        color: const Color(0xFF0A66C2),
        onTap: () => _launch(
          context,
          'linkedin://shareArticle?text=${Uri.encodeComponent(_message)}',
          fallbackUrl:
          'https://www.linkedin.com/shareArticle?text=${Uri.encodeComponent(_message)}',
        ),
      ),
      _BrandPlatform(
        icon: FontAwesomeIcons.xTwitter,
        label: 'X (Twitter)',
        color: Colors.white,
        onTap: () => _launch(
          context,
          'twitter://post?message=${Uri.encodeComponent(_message)}',
          fallbackUrl:
          'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_message)}',
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: platforms.map((p) => _BrandButton(platform: p)).toList(),
    );
  }
}

class _BrandPlatform {
  final IconData   icon;
  final String     label;
  final Color      color;
  final VoidCallback onTap;
  const _BrandPlatform({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });
}

class _BrandButton extends StatelessWidget {
  final _BrandPlatform platform;
  const _BrandButton({required this.platform});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        platform.onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: platform.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: platform.color.withValues(alpha: 0.3)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: platform.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(platform.icon, color: platform.color, size: 22),
            ),
          ),
          const SizedBox(height: 8),
          Text(platform.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: platform.color, fontSize: 11,
                  fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        ]),
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final HealthProvider hp;
  final String name;
  const _QuickActions({required this.hp, required this.name});

  String get _message =>
      'I scored ${hp.score.toInt()}/100 on GoFaster Health today! 💪⚡ '
      'Join me: https://gofaster.in #GoFaster #StayActive';

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _buildActionBtn(
          icon: Icons.share_rounded,
          label: 'Share Now',
          color: AppColors.primary,
          onTap: () {
            HapticFeedback.lightImpact();
            Share.share(_message, subject: 'My GoFaster Score');
          },
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildActionBtn(
          icon: Icons.link_rounded,
          label: 'Copy Link',
          color: const Color(0xFF00BCD4),
          onTap: () async {
            await Clipboard.setData(
                const ClipboardData(text: 'https://gofaster.in'));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.surface,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                content: Row(children: const [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF66BB6A)),
                  SizedBox(width: 8),
                  Text('Link copied! gofaster.in',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ]),
              ));
            }
          },
        ),
      ),
    ]);
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
                color: color, fontWeight: FontWeight.w700,
                fontSize: 13, fontFamily: 'Poppins')),
          ]),
        ),
      );
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.h4.copyWith(fontSize: 16));
  }
}
