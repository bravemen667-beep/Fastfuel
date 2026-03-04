// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Help & Support Screen
//  FAQ accordion + Email/Phone/WhatsApp/Website contact buttons + Shopify banner
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'inapp_browser_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedIndex;

  static const _faqs = [
    _FAQ(
      q: 'What is the GoFaster Score?',
      a: 'The GoFaster Score (0–100) is your personalised daily health index. '
         'It combines four equally-weighted pillars: Hydration (25 pts), Sleep (25 pts), '
         'Nutrition/Vitamins (25 pts) and Activity (25 pts). Scores above 80 are excellent!',
    ),
    _FAQ(
      q: 'How does Health Connect / HealthKit sync work?',
      a: 'GoFaster reads your sleep, steps, active calories and heart rate directly from '
         'Google Health Connect (Android) or Apple HealthKit (iOS). Grant permission once and '
         'your data refreshes automatically. You can pull-to-refresh any screen for the latest data.',
    ),
    _FAQ(
      q: 'Why is my sleep data not showing?',
      a: 'Ensure you have granted Health Connect / HealthKit sleep permissions. '
         'Also check that your wearable (Fitbit, Garmin, Apple Watch) is synced to the '
         'health platform. Pull-to-refresh the Sleep Analysis screen to re-trigger sync.',
    ),
    _FAQ(
      q: 'How do I set up hydration reminders?',
      a: 'Go to Profile → Settings → Notifications and enable the Hydration Reminder toggle. '
         'You will receive a push notification every 90 minutes between 8:00 AM and 10:00 PM '
         'via Firebase Cloud Messaging. Tapping the notification opens the Hydration screen.',
    ),
    _FAQ(
      q: 'What is the GoFaster Tablet?',
      a: 'The GoFaster Tablet is a scientifically formulated supplement with Vitamin C + B12 '
         'designed to support immunity, energy and focus. Order directly from our Shopify store '
         'at gofaster.in.',
    ),
    _FAQ(
      q: 'How does the AI Workout feature work?',
      a: 'Claude AI (Sonnet) analyses your current GoFaster Score, sleep quality, fitness goal '
         'and preferred workout type to generate a personalised workout plan. Set your fitness '
         'preferences in Profile → Fitness Preferences for best results.',
    ),
    _FAQ(
      q: 'How do I scan food to log calories?',
      a: 'On the Home screen, tap "Scan Food" in Quick Actions. Point your camera at the food '
         'and GoFaster uses Google ML Kit to identify it. If not recognised, it falls back to '
         'the Open Food Facts database. Confirm the item to log calories to your dashboard.',
    ),
    _FAQ(
      q: 'How do I connect Google Fit?',
      a: 'On the Home screen, tap the "Connect Google Fit" banner. You will be prompted to '
         'sign in with your Google account. GoFaster will then sync your steps, calories and '
         'active minutes from Google Fit via the Fitness REST API.',
    ),
    _FAQ(
      q: 'Is my health data safe?',
      a: 'Yes. GoFaster only reads health data and does not sell or share it with third parties. '
         'Data is stored in Firebase Firestore with industry-standard encryption. You can revoke '
         'permissions at any time from your device Health settings.',
    ),
    _FAQ(
      q: 'How do I share my progress?',
      a: 'Go to Profile → Share Progress. GoFaster generates a branded progress card with your '
         'score, streaks and weekly stats. Tap Share to open the native share sheet (WhatsApp, '
         'Instagram, LinkedIn, Snapchat, etc.).',
    ),
    _FAQ(
      q: 'Can I use GoFaster without health permissions?',
      a: 'Yes! If you decline Health Connect / HealthKit permissions, GoFaster falls back to '
         'manual entry mode. You can log water, meals, vitamins and sleep manually. '
         'Your GoFaster Score will still be calculated based on manual entries.',
    ),
    _FAQ(
      q: 'How do I cancel or delete my account?',
      a: 'To delete your account, email us at Info@gofaster.in with the subject "Account Deletion". '
         'We will process your request within 48 hours and delete all associated data.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                _buildShopifyBanner(context),
                const SizedBox(height: 24),
                _buildContactSection(context),
                const SizedBox(height: 24),
                _buildFAQSection(),
                const SizedBox(height: 24),
                _buildFooter(),
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
            child: Text('Help & Support', style: AppTextStyles.h3),
          ),
        ),
      ),
    );
  }

  // ── Shopify Store Banner ───────────────────────────────────────────────────
  Widget _buildShopifyBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => InAppBrowserScreen.open(context, url: 'https://gofaster.in', title: 'GoFaster Shop'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20, spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shop GoFaster Products',
                    style: AppTextStyles.h4.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vitamins, supplements & wellness essentials',
                    style: AppTextStyles.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  Text('Shop',
                    style: AppTextStyles.buttonSm.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Contact Buttons ───────────────────────────────────────────────────────
  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Us', style: AppTextStyles.h4),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _ContactTile(
                icon: Icons.email_rounded,
                color: AppColors.primary,
                title: 'Email Support',
                subtitle: 'Info@gofaster.in',
                trailing: 'Reply within 24h',
                onTap: () => _launchUrl('mailto:Info@gofaster.in?subject=GoFaster%20App%20Support'),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.border),
              _ContactTile(
                icon: Icons.phone_rounded,
                color: const Color(0xFF25D366),
                title: 'Phone / WhatsApp',
                subtitle: '+91 73739 17379',
                trailing: 'Mon–Sat 9am–6pm',
                onTap: () => _launchUrl('https://wa.me/917373917379?text=Hi%20GoFaster%20Support!'),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.border),
              _ContactTile(
                icon: Icons.language_rounded,
                color: const Color(0xFF2196F3),
                title: 'Website',
                subtitle: 'gofaster.in',
                trailing: 'Visit now',
                onTap: () => _launchUrl('https://gofaster.in'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── FAQ Accordion ────────────────────────────────────────────────────────
  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('FAQ', style: AppTextStyles.h4),
            Text('${_faqs.length} questions',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _faqs.asMap().entries.map((e) {
              final i = e.key;
              final faq = e.value;
              final expanded = _expandedIndex == i;
              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() =>
                      _expandedIndex = expanded ? null : i,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              faq.q,
                              style: AppTextStyles.body.copyWith(
                                color: expanded
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: expanded
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: expanded
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          faq.a,
                          style: AppTextStyles.bodySm.copyWith(height: 1.6),
                        ),
                      ),
                    ),
                    crossFadeState: expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                  if (i < _faqs.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text('GoFaster Health v1.0.0',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _launchUrl('https://gofaster.in'),
            child: Text('gofaster.in',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2025 GoFaster Health. All rights reserved.',
            style: AppTextStyles.label.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    // gofaster.in URLs → in-app browser; everything else → external app
    if (url.contains('gofaster.in') && !url.startsWith('mailto:') && !url.startsWith('tel:') && !url.contains('wa.me')) {
      if (mounted) {
        await InAppBrowserScreen.open(context, url: url, title: 'GoFaster');
      }
      return;
    }
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

// ── Contact Tile ─────────────────────────────────────────────────────────────
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon, required this.color,
    required this.title, required this.subtitle,
    required this.trailing, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h5),
                  Text(subtitle,
                    style: AppTextStyles.bodySm.copyWith(color: color),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(trailing,
                  style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAQ data class ────────────────────────────────────────────────────────────
class _FAQ {
  final String q;
  final String a;
  const _FAQ({required this.q, required this.a});
}
