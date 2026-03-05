// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Fitness Preferences Screen
//  Goal selector, Workout type selector, Fitness level selector.
//  Saves to Firestore → used by AI workout suggestion engine.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class FitnessPreferencesScreen extends StatefulWidget {
  const FitnessPreferencesScreen({super.key});

  @override
  State<FitnessPreferencesScreen> createState() =>
      _FitnessPreferencesScreenState();
}

class _FitnessPreferencesScreenState extends State<FitnessPreferencesScreen> {
  // ── Goal options ──────────────────────────────────────────────────────────
  static const _goals = [
    _PrefOption(
      icon: Icons.monitor_weight_rounded,
      label: 'Weight Loss',
      description: 'Burn fat and reduce body weight',
      color: Color(0xFFFF6B00),
    ),
    _PrefOption(
      icon: Icons.fitness_center_rounded,
      label: 'Build Muscle',
      description: 'Increase strength and muscle mass',
      color: Color(0xFF9C27B0),
    ),
    _PrefOption(
      icon: Icons.directions_run_rounded,
      label: 'Improve Endurance',
      description: 'Boost cardiovascular fitness',
      color: Color(0xFF2196F3),
    ),
    _PrefOption(
      icon: Icons.self_improvement_rounded,
      label: 'General Wellness',
      description: 'Stay healthy and active',
      color: Color(0xFF4CAF50),
    ),
    _PrefOption(
      icon: Icons.sports_gymnastics_rounded,
      label: 'Flexibility',
      description: 'Improve mobility and range of motion',
      color: Color(0xFFFFB347),
    ),
    _PrefOption(
      icon: Icons.local_fire_department_rounded,
      label: 'Performance',
      description: 'Peak athletic performance',
      color: Color(0xFFFF4444),
    ),
  ];

  // ── Workout type options ──────────────────────────────────────────────────
  static const _workoutTypes = [
    _PrefOption(icon: Icons.flash_on_rounded,         label: 'HIIT',       description: 'High Intensity Interval Training', color: Color(0xFFFF6B00)),
    _PrefOption(icon: Icons.fitness_center_rounded,   label: 'Strength',   description: 'Weight & resistance training',      color: Color(0xFF9C27B0)),
    _PrefOption(icon: Icons.directions_bike_rounded,  label: 'Cardio',     description: 'Running, cycling, swimming',        color: Color(0xFF2196F3)),
    _PrefOption(icon: Icons.self_improvement_rounded, label: 'Yoga',       description: 'Mindful movement & breathwork',     color: Color(0xFF4CAF50)),
    _PrefOption(icon: Icons.sports_martial_arts_rounded, label: 'MMA',    description: 'Mixed martial arts & combat',       color: Color(0xFFFF4444)),
    _PrefOption(icon: Icons.pool_rounded,             label: 'Swimming',   description: 'Low-impact full body workout',      color: Color(0xFF00BCD4)),
    _PrefOption(icon: Icons.sports_basketball_rounded,label: 'Sports',     description: 'Team & recreational sports',        color: Color(0xFFFFB347)),
    _PrefOption(icon: Icons.accessibility_new_rounded,label: 'Pilates',    description: 'Core strength & body conditioning', color: Color(0xFFE91E63)),
  ];

  // ── Fitness level options ─────────────────────────────────────────────────
  static const _levels = [
    _PrefOption(
      icon: Icons.star_outline_rounded,
      label: 'Beginner',
      description: 'New to fitness, starting out',
      color: Color(0xFF4CAF50),
    ),
    _PrefOption(
      icon: Icons.star_half_rounded,
      label: 'Intermediate',
      description: '6-12 months of regular training',
      color: Color(0xFFFFB347),
    ),
    _PrefOption(
      icon: Icons.star_rounded,
      label: 'Advanced',
      description: 'Experienced athlete, high intensity',
      color: Color(0xFFFF6B00),
    ),
    _PrefOption(
      icon: Icons.emoji_events_rounded,
      label: 'Elite',
      description: 'Competitive or professional level',
      color: Color(0xFFFF4444),
    ),
  ];

  String _selectedGoal        = 'General Wellness';
  List<String> _selectedTypes = ['HIIT'];
  String _selectedLevel       = 'Intermediate';
  bool _saving = false;
  bool _saved  = false;

  @override
  void initState() {
    super.initState();
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    final auth = context.read<GFAuthProvider>();
    if (auth.uid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.uid)
          .collection('profile')
          .doc('fitness_preferences')
          .get();
      if (doc.exists && mounted) {
        final d = doc.data()!;
        setState(() {
          _selectedGoal  = (d['goal']  as String?) ?? _selectedGoal;
          _selectedLevel = (d['level'] as String?) ?? _selectedLevel;
          final types = d['workoutTypes'];
          if (types is List) {
            _selectedTypes = List<String>.from(types);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() { _saving = true; _saved = false; });
    final auth = context.read<GFAuthProvider>();
    if (auth.uid.isEmpty) {
      setState(() => _saving = false);
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.uid)
          .collection('profile')
          .doc('fitness_preferences')
          .set({
        'goal':         _selectedGoal,
        'workoutTypes': _selectedTypes,
        'level':        _selectedLevel,
        'updatedAt':    FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update the main profile doc for AI context
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.uid)
          .set({
        'fitnessGoal':     _selectedGoal,
        'fitnessLevel':    _selectedLevel,
        'preferredWorkout': _selectedTypes.isNotEmpty ? _selectedTypes.first : 'HIIT',
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() { _saving = false; _saved = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text('Preferences saved! AI will personalise your workouts.',
                style: AppTextStyles.bodySm.copyWith(color: Colors.white),
              ),
            ]),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAiBanner(),
                const SizedBox(height: 24),
                _buildSectionHeader('Your Fitness Goal'),
                const SizedBox(height: 12),
                _buildGoalGrid(),
                const SizedBox(height: 24),
                _buildSectionHeader('Preferred Workout Types'),
                Text('Select all that apply',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                _buildWorkoutTypeGrid(),
                const SizedBox(height: 24),
                _buildSectionHeader('Fitness Level'),
                const SizedBox(height: 12),
                _buildLevelSelector(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 40),
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
                Text('Fitness Preferences', style: AppTextStyles.h3),
                if (_saved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_rounded, color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text('Saved', style: AppTextStyles.label.copyWith(color: AppColors.success)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI-Powered Workouts', style: AppTextStyles.h5.copyWith(color: AppColors.accent)),
                const SizedBox(height: 2),
                Text(
                  'Claude AI uses your preferences, GoFaster Score, sleep quality and fitness level to create personalised workout plans.',
                  style: AppTextStyles.bodySm.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: AppTextStyles.h4),
    );
  }

  Widget _buildGoalGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: _goals.map((g) {
        final selected = _selectedGoal == g.label;
        return GestureDetector(
          onTap: () => setState(() => _selectedGoal = g.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? g.color.withValues(alpha: 0.15) : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? g.color : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(g.icon, color: selected ? g.color : AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(g.label,
                    style: AppTextStyles.bodySm.copyWith(
                      color: selected ? g.color : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: g.color, size: 14),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutTypeGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _workoutTypes.map((t) {
        final selected = _selectedTypes.contains(t.label);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                if (_selectedTypes.length > 1) _selectedTypes.remove(t.label);
              } else {
                _selectedTypes.add(t.label);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? t.color.withValues(alpha: 0.12) : AppColors.surface,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: selected ? t.color : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.icon, color: selected ? t.color : AppColors.textMuted, size: 16),
                const SizedBox(width: 6),
                Text(t.label,
                  style: AppTextStyles.bodySm.copyWith(
                    color: selected ? t.color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLevelSelector() {
    return Column(
      children: _levels.map((l) {
        final selected = _selectedLevel == l.label;
        return GestureDetector(
          onTap: () => setState(() => _selectedLevel = l.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? l.color.withValues(alpha: 0.10) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? l.color : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(l.icon, color: selected ? l.color : AppColors.textMuted, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.label,
                        style: AppTextStyles.h5.copyWith(
                          color: selected ? l.color : AppColors.textPrimary,
                        ),
                      ),
                      Text(l.description, style: AppTextStyles.bodySm),
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: l.color, shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  )
                else
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Save Preferences', style: AppTextStyles.button),
                ],
              ),
      ),
    );
  }
}

class _PrefOption {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  const _PrefOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}
