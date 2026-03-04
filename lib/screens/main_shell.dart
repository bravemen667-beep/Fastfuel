import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'hydration_screen.dart';
import 'calorie_screen.dart';
import 'sleep_screen.dart';
import 'profile_screen.dart';

// Global key so any screen can switch tabs
final mainShellKey = GlobalKey<_MainShellState>();

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  // Static helper: switch to tab from anywhere
  static void switchTab(int index) {
    mainShellKey.currentState?._switchTab(index);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _switchTab(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  static const _screens = [
    HomeScreen(),
    HydrationScreen(),
    CalorieScreen(),   // index 2 = Fuel ⚡ tab
    SleepScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
