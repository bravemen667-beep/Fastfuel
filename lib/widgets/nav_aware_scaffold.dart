// ─────────────────────────────────────────────────────────────────────────────
//  NavAwareScaffold — wraps a detail screen with persistent bottom navigation
//  so users are never lost. Tapping a tab pops back to the shell and switches.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../theme/app_theme.dart';
import '../screens/main_shell.dart';

class NavAwareScaffold extends StatelessWidget {
  final Widget body;
  final int activeTab; // which tab this screen "belongs to"

  const NavAwareScaffold({
    super.key,
    required this.body,
    this.activeTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: body,
      bottomNavigationBar: AppBottomNav(
        currentIndex: activeTab,
        onTap: (i) {
          if (i == activeTab) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            Navigator.popUntil(context, (route) => route.isFirst);
            MainShell.switchTab(i);
          }
        },
      ),
    );
  }
}
