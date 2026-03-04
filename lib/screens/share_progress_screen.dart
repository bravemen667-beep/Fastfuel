// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Share Progress Screen
//  Generates a shareable image card with GoFaster Score, streaks, weekly stats
//  and GoFaster branding. Opens native share sheet (WhatsApp, Instagram, etc.)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../providers/auth_provider.dart';

class ShareProgressScreen extends StatefulWidget {
  const ShareProgressScreen({super.key});

  @override
  State<ShareProgressScreen> createState() => _ShareProgressScreenState();
}

class _ShareProgressScreenState extends State<ShareProgressScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareCard() async {
    setState(() => _sharing = true);
    try {
      // Capture the widget as an image
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _sharing = false);
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        setState(() => _sharing = false);
        return;
      }
      final pngBytes = byteData.buffer.asUint8List();

      // Read context-dependent values before async gap
      if (!mounted) return;
      final hp   = context.read<HealthProvider>();
      final scoreInt  = hp.score.toInt();
      final waterPct  = (hp.waterProgress * 100).toInt();
      final sleepDur  = hp.sleepDuration;
      final calsBurned = hp.caloriesBurned.toInt();

      // Share via native share sheet
      await Share.shareXFiles(
        [XFile.fromData(pngBytes, name: 'gofaster_progress.png', mimeType: 'image/png')],
        subject: 'My GoFaster Health Progress',
        text:
            '🚀 Check out my GoFaster Score: $scoreInt/100!\n'
            '💧 Water: $waterPct% · '
            '😴 Sleep: $sleepDur · '
            '🔥 $calsBurned kcal burned\n'
            '🌐 https://gofaster.in',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _copyLink() async {
    // Deep link / short link to the GoFaster store
    await Share.share(
      '🚀 I\'m tracking my health with GoFaster! Check it out 👉 https://gofaster.in\n'
      'My score today: ${context.read<HealthProvider>().score.toInt()}/100 💪',
      subject: 'GoFaster Health App',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hp   = context.watch<HealthProvider>();
    final auth = context.watch<AuthProvider>();
    final displayName = hp.profileName.isNotEmpty
        ? hp.profileName
        : (auth.userName.isEmpty ? 'GoFaster User' : auth.userName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Preview your progress card below and share it with the world! 🌍',
                  style: AppTextStyles.bodySm.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),

                // ── Shareable Card (captured as image) ──────────────────────
                RepaintBoundary(
                  key: _cardKey,
                  child: _ShareCard(hp: hp, displayName: displayName),
                ),

                const SizedBox(height: 32),

                // ── Share Buttons ──────────────────────────────────────────
                Text('Share via', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                _buildShareButtons(),

                const SizedBox(height: 24),
                _buildCopyLinkButton(),

                const SizedBox(height: 24),
                _buildHashtagsCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 70,
      floating: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 16),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(60, 0, 20, 0),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Share Progress', style: AppTextStyles.h3),
                GestureDetector(
                  onTap: _sharing ? null : _shareCard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppGradients.fire,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: _sharing
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(children: [
                            const Icon(Icons.share_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text('Share', style: AppTextStyles.buttonSm),
                          ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButtons() {
    final hp = context.read<HealthProvider>();
    final score = hp.score.toInt();
    final rawMsg =
      'I just scored $score/100 on GoFaster Health App! 💪⚡\n'
      'Tracking water 💧, sleep 😴, vitamins & calories daily.\n'
      'Get GoFaster 👉 https://gofaster.in #GoFaster #StayActive';
    final shareMsg = Uri.encodeComponent(rawMsg);

    final platforms = [
      _BrandPlatform(
        label: 'WhatsApp',
        bgColor: const Color(0xFF25D366),
        icon: const _WhatsAppIcon(),
        onTap: () => _launchUrl('https://wa.me/?text=$shareMsg'),
      ),
      _BrandPlatform(
        label: 'Instagram',
        bgColor: const Color(0xFFE1306C),
        icon: const _InstagramIcon(),
        onTap: () => _shareCard(),
      ),
      _BrandPlatform(
        label: 'Snapchat',
        bgColor: const Color(0xFFFFFC00),
        icon: const _SnapchatIcon(),
        onTap: () => _shareCard(),
      ),
      _BrandPlatform(
        label: 'LinkedIn',
        bgColor: const Color(0xFF0A66C2),
        icon: const _LinkedInIcon(),
        onTap: () => _launchUrl(
          'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent('https://gofaster.in')}',
        ),
      ),
      _BrandPlatform(
        label: 'X',
        bgColor: const Color(0xFF000000),
        icon: const _XIcon(),
        onTap: () => _launchUrl(
          'https://twitter.com/intent/tweet?text=$shareMsg',
        ),
      ),
    ];

    return Row(
      children: platforms.asMap().entries.map((e) {
        final i = e.key;
        final p = e.value;
        final isLast = i == platforms.length - 1;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              p.onTap();
            },
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 6),
              child: Column(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: p.bgColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.bgColor.withValues(alpha: 0.4)),
                    ),
                    child: Center(child: p.icon),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.label,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textMuted, fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to share sheet
        await _shareCard();
      }
    } catch (_) {
      await _shareCard();
    }
  }

  Widget _buildCopyLinkButton() {
    return GestureDetector(
      onTap: _copyLink,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Copy Short Link', style: AppTextStyles.h5),
                  Text('Share gofaster.in with a personalised message',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildHashtagsCard() {
    const tags = ['#GoFaster', '#HealthGoals', '#FitnessMotivation',
                   '#Hydration', '#SleepWell', '#GoFasterHealth'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggested Hashtags', style: AppTextStyles.h5),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(t,
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── The shareable card widget ────────────────────────────────────────────────
class _ShareCard extends StatelessWidget {
  final HealthProvider hp;
  final String displayName;
  const _ShareCard({required this.hp, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 40, spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.fire,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GoFaster Health',
                      style: AppTextStyles.h5.copyWith(color: AppColors.primary),
                    ),
                    Text(displayName,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Score
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GoFaster Score',
                      style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(hp.score.toInt().toString(),
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primary, fontSize: 52,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text('/100',
                            style: AppTextStyles.h4.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ShareStat('🔥', '${hp.streakDays}d', 'Streak'),
                  const SizedBox(height: 8),
                  _ShareStat('⚡', '${hp.activeMinutes}', 'Active min'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _ShareStatBox(
                emoji: '💧',
                value: '${(hp.waterProgress * 100).toInt()}%',
                label: 'Hydration',
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(width: 10),
              _ShareStatBox(
                emoji: '😴',
                value: hp.sleepDuration,
                label: 'Sleep',
                color: const Color(0xFF9C27B0),
              ),
              const SizedBox(width: 10),
              _ShareStatBox(
                emoji: '🔥',
                value: '${hp.caloriesBurned.toInt()}',
                label: 'kcal',
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _ShareStatBox(
                emoji: '👣',
                value: '${(hp.steps / 1000).toStringAsFixed(1)}k',
                label: 'Steps',
                color: AppColors.success,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 7-day sleep trend mini-chart
          if (hp.sleepWeekly.isNotEmpty) ...[
            Text('7-Day Trend',
              style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: hp.sleepWeekly.asMap().entries.map((e) {
                  final isLast = e.key == hp.sleepWeekly.length - 1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 3),
                      child: FractionallySizedBox(
                        heightFactor: e.value.clamp(0.1, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isLast
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('gofaster.in',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppGradients.fire,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text('GoFaster Health', style: AppTextStyles.label.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _ShareStat(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary,
            )),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ],
    );
  }
}

class _ShareStatBox extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  const _ShareStatBox({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.bodySm.copyWith(
              color: color, fontWeight: FontWeight.w700, fontSize: 12,
            )),
            Text(label, style: AppTextStyles.label.copyWith(fontSize: 8)),
          ],
        ),
      ),
    );
  }
}

// ── Brand platform data class ────────────────────────────────────────────────
class _BrandPlatform {
  final Widget icon;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;
  const _BrandPlatform({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.onTap,
  });
}

// ── WhatsApp icon (green phone-in-chat) ─────────────────────────────────────
class _WhatsAppIcon extends StatelessWidget {
  const _WhatsAppIcon();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(26, 26),
    painter: _WhatsAppPainter(),
  );
}
class _WhatsAppPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF25D366)..style = PaintingStyle.fill;
    // Outer circle
    canvas.drawCircle(Offset(size.width/2, size.height/2), size.width/2, p);
    // White phone bubble
    final wp = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.35;
    path.addOval(Rect.fromCircle(center: Offset(cx, cy - 1), radius: r));
    canvas.drawPath(path, wp);
    // Tail
    final tailP = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final tail = Path();
    tail.moveTo(cx - r * 0.3, cy + r * 0.7);
    tail.lineTo(cx - r * 0.7, cy + r * 1.1);
    tail.lineTo(cx + r * 0.1, cy + r * 0.5);
    tail.close();
    canvas.drawPath(tail, tailP);
    // Phone icon inside
    final phonePaint = Paint()..color = Colors.white..style = PaintingStyle.stroke
      ..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(cx - 4, cy - 5)
        ..lineTo(cx - 4, cy + 5)
        ..arcTo(Rect.fromLTWH(cx - 4, cy + 3, 8, 4), 3.14, -3.14, false)
        ..lineTo(cx + 4, cy - 5)
        ..arcTo(Rect.fromLTWH(cx - 4, cy - 7, 8, 4), 0, 3.14, false),
      phonePaint,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Instagram icon (camera gradient) ────────────────────────────────────────
class _InstagramIcon extends StatelessWidget {
  const _InstagramIcon();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(26, 26),
    painter: _InstagramPainter(),
  );
}
class _InstagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Gradient bg
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(7)), bgPaint);
    // Camera outline
    final wp = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: size.width * 0.7, height: size.height * 0.6),
        const Radius.circular(4),
      ),
      wp,
    );
    // Lens
    canvas.drawCircle(Offset(cx, cy), size.width * 0.18, wp);
    // Flash
    final fp = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + size.width * 0.24, cy - size.height * 0.21), 2, fp);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Snapchat ghost icon ──────────────────────────────────────────────────────
class _SnapchatIcon extends StatelessWidget {
  const _SnapchatIcon();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(26, 26),
    painter: _SnapchatPainter(),
  );
}
class _SnapchatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFFFFC00)..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(7)),
      p,
    );
    // Ghost shape (simplified)
    final gp = Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.fill;
    final ghost = Path();
    final cx = size.width / 2;
    final cy = size.height / 2 - 1;
    ghost.moveTo(cx - 6, cy + 6);
    ghost.lineTo(cx - 6, cy - 3);
    ghost.arcToPoint(Offset(cx + 6, cy - 3), radius: const Radius.circular(6), clockwise: false);
    ghost.lineTo(cx + 6, cy + 6);
    // Wavy bottom
    ghost.lineTo(cx + 4, cy + 4);
    ghost.lineTo(cx + 2, cy + 6);
    ghost.lineTo(cx, cy + 4);
    ghost.lineTo(cx - 2, cy + 6);
    ghost.lineTo(cx - 4, cy + 4);
    ghost.close();
    canvas.drawPath(ghost, gp);
    // Eyes
    final ep = Paint()..color = const Color(0xFFFFFC00)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 2.5, cy - 1), 1.5, ep);
    canvas.drawCircle(Offset(cx + 2.5, cy - 1), 1.5, ep);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── LinkedIn icon ────────────────────────────────────────────────────────────
class _LinkedInIcon extends StatelessWidget {
  const _LinkedInIcon();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(26, 26),
    painter: _LinkedInPainter(),
  );
}
class _LinkedInPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF0A66C2)..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(7)),
      p,
    );
    final wp = Paint()..color = Colors.white..style = PaintingStyle.fill;
    // "in" text using rects
    // dot
    canvas.drawRect(Rect.fromLTWH(5, 7, 3, 3), wp);
    // vertical bar l
    canvas.drawRect(Rect.fromLTWH(5, 12, 3, 8), wp);
    // vertical bar n
    canvas.drawRect(Rect.fromLTWH(10, 12, 3, 8), wp);
    // n-arch
    final arc = Paint()..color = Colors.white..style = PaintingStyle.stroke
      ..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(10, 10, 6, 6), -3.14, 3.14, false, arc,
    );
    canvas.drawRect(Rect.fromLTWH(16, 12, 3, 8), wp);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── X (Twitter) icon ────────────────────────────────────────────────────────
class _XIcon extends StatelessWidget {
  const _XIcon();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(26, 26),
    painter: _XPainter(),
  );
}
class _XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF000000)..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(7)),
      p,
    );
    final wp = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    // X mark
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.75),
      wp,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.25),
      Offset(size.width * 0.25, size.height * 0.75),
      wp,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
