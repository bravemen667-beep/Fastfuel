import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _inactiveColor = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(5, (i) {
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 44 : 36,
                          height: selected ? 36 : 32,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: i == 2
                                ? Icon(
                                    selected
                                        ? Icons.bolt_rounded
                                        : Icons.bolt_outlined,
                                    color: selected
                                        ? AppColors.primary
                                        : _inactiveColor,
                                    size: selected ? 24 : 22,
                                  )
                                : Icon(
                                    _iconFor(i, selected),
                                    color: selected
                                        ? AppColors.primary
                                        : _inactiveColor,
                                    size: selected ? 22 : 20,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? AppColors.primary
                                : _inactiveColor,
                          ),
                          child: Text(_labelFor(i)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(int i, bool selected) {
    switch (i) {
      case 0: return selected ? Icons.home_rounded : Icons.home_outlined;
      case 1: return selected ? Icons.water_drop_rounded : Icons.water_drop_outlined;
      case 3: return selected ? Icons.bedtime_rounded : Icons.bedtime_outlined;
      case 4: return selected ? Icons.person_rounded : Icons.person_outline_rounded;
      default: return Icons.bolt_rounded;
    }
  }

  String _labelFor(int i) {
    switch (i) {
      case 0: return 'Home';
      case 1: return 'Water';
      case 2: return 'Fuel';
      case 3: return 'Sleep';
      case 4: return 'Profile';
      default: return '';
    }
  }
}
