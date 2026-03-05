// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Food Scanner Screen (4-mode complete rebuild)
//  Reference: MyFitnessPal, Cronometer
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../widgets/common_widgets.dart';

// ─── Meal types ───────────────────────────────────────────────────────────────
enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExt on MealType {
  String get label => name[0].toUpperCase() + name.substring(1);
  IconData get icon {
    switch (this) {
      case MealType.breakfast: return Icons.wb_sunny_rounded;
      case MealType.lunch:     return Icons.lunch_dining_rounded;
      case MealType.dinner:    return Icons.dinner_dining_rounded;
      case MealType.snack:     return Icons.cookie_rounded;
    }
  }
}

// ─── Food Result model ────────────────────────────────────────────────────────
class FoodResult {
  final String  name;
  final int     calories;
  final double  protein;
  final double  carbs;
  final double  fat;
  final List<FoodIngredient> ingredients;
  final String? imagePath;

  const FoodResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    this.imagePath,
  });
}

class FoodIngredient {
  final String name;
  final int    kcal;
  const FoodIngredient(this.name, this.kcal);
}

// ─── Mock AI analysis ─────────────────────────────────────────────────────────
FoodResult _mockAnalyse(String hint, {int? seed}) {
  final rng    = math.Random(seed ?? hint.hashCode.abs());
  final meals  = [
    FoodResult(name: 'Vegetable Salad', calories: 285, protein: 8, carbs: 32, fat: 12,
        ingredients: [FoodIngredient('Avocado', 74), FoodIngredient('Carrot', 36),
          FoodIngredient('Vegetables', 24), FoodIngredient('Dressing', 45), FoodIngredient('Nuts', 106)]),
    FoodResult(name: 'Chicken Rice Bowl', calories: 520, protein: 38, carbs: 62, fat: 14,
        ingredients: [FoodIngredient('Chicken', 220), FoodIngredient('Rice', 180),
          FoodIngredient('Vegetables', 45), FoodIngredient('Sauce', 75)]),
    FoodResult(name: 'Masala Dal', calories: 340, protein: 18, carbs: 54, fat: 7,
        ingredients: [FoodIngredient('Dal', 180), FoodIngredient('Tomato', 35),
          FoodIngredient('Spices', 25), FoodIngredient('Oil', 100)]),
    FoodResult(name: 'Paneer Tikka', calories: 430, protein: 24, carbs: 18, fat: 28,
        ingredients: [FoodIngredient('Paneer', 260), FoodIngredient('Capsicum', 30),
          FoodIngredient('Marinade', 80), FoodIngredient('Oil', 60)]),
    FoodResult(name: 'Mixed Fruit Bowl', calories: 180, protein: 3, carbs: 44, fat: 1,
        ingredients: [FoodIngredient('Apple', 52), FoodIngredient('Banana', 89),
          FoodIngredient('Mango', 39)]),
    FoodResult(name: 'Oatmeal Bowl', calories: 310, protein: 12, carbs: 56, fat: 6,
        ingredients: [FoodIngredient('Oats', 150), FoodIngredient('Milk', 80),
          FoodIngredient('Berries', 45), FoodIngredient('Honey', 35)]),
  ];
  return meals[rng.nextInt(meals.length)];
}

FoodResult _mockBarcode(String code) {
  final products = [
    FoodResult(name: 'Britannia NutriChoice', calories: 120, protein: 2, carbs: 20, fat: 4,
        ingredients: [FoodIngredient('Wheat', 80), FoodIngredient('Oats', 25), FoodIngredient('Sugar', 15)]),
    FoodResult(name: 'Amul Butter', calories: 740, protein: 1, carbs: 0, fat: 82,
        ingredients: [FoodIngredient('Cream', 740)]),
    FoodResult(name: 'Protein Bar (MuscleBlaze)', calories: 200, protein: 20, carbs: 20, fat: 5,
        ingredients: [FoodIngredient('Whey', 120), FoodIngredient('Oats', 50), FoodIngredient('Nuts', 30)]),
  ];
  return products[code.hashCode.abs() % products.length];
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class ScanFoodScreen extends StatefulWidget {
  final MealType? mealType;
  const ScanFoodScreen({super.key, this.mealType});

  @override
  State<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends State<ScanFoodScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabs;
  int _activeMode = 0;

  // ── scan state ─────────────────────────────────────────────────────────────
  bool         _scanning  = false;
  FoodResult?  _result;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this, initialIndex: _activeMode);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) {
        setState(() {
          _activeMode = _tabs.index;
          _result     = null;
          _scanning   = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── AI Photo analysis ──────────────────────────────────────────────────────
  Future<void> _captureAndAnalyse() async {
    setState(() { _scanning = true; _result = null; });
    HapticFeedback.mediumImpact();
    // Simulate camera capture + network delay
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final res = _mockAnalyse('camera_snap_${DateTime.now().millisecond}');
    setState(() { _scanning = false; _result = res; });
  }

  Future<void> _pickFromGallery() async {
    setState(() { _scanning = true; _result = null; });
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (img == null) { setState(() => _scanning = false); return; }
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      final res = _mockAnalyse(img.name);
      setState(() { _scanning = false; _result = res; });
    } catch (_) {
      setState(() => _scanning = false);
    }
  }

  Future<void> _searchByText(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _scanning = true; _result = null; });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final res = _mockAnalyse(query.toLowerCase(), seed: query.hashCode);
    setState(() { _scanning = false; _result = res; });
  }

  Future<void> _mockBarcodeScan() async {
    setState(() { _scanning = true; _result = null; });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final res = _mockBarcode('8901030888564');
    setState(() { _scanning = false; _result = res; });
  }

  void _discardResult() => setState(() => _result = null);

  void _addToMealLog(FoodResult food, MealType mealType) async {
    HapticFeedback.lightImpact();
    try {
      final hp  = context.read<HealthProvider>();
      hp.addMealCalories(food.calories.toDouble(), food.name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '${food.name} added to ${mealType.label} (${food.calories} kcal)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            )),
          ]),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white70,
            onPressed: () {},
          ),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to log meal. Try again.'),
      ));
    }
    final _ = DateTime.now();
  }

  void _showMealTypeSheet(FoodResult food) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Add to Meal Log', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text('${food.name} · ${food.calories} kcal',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ...MealType.values.map((mt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () { Navigator.pop(context); _addToMealLog(food, mt); },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(mt.icon, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text(mt.label, style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppColors.textMuted, size: 14),
                  ]),
                ),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(child: _buildBody()),
          _buildTabBar(),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text('Scan Food', style: AppTextStyles.h3.copyWith(color: Colors.white)),
        ),
        if (_result != null && !_scanning)
          GestureDetector(
            onTap: _discardResult,
            child: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 26),
          ),
      ]),
    );
  }

  Widget _buildTabBar() {
    const labels = ['Scan Food', 'Barcode', 'Food Label', 'Gallery'];
    const icons  = [Icons.camera_alt_rounded, Icons.qr_code_scanner_rounded,
      Icons.document_scanner_rounded, Icons.photo_library_rounded];
    return Container(
      color: const Color(0xFF111111),
      child: TabBar(
        controller: _tabs,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            fontFamily: 'Poppins'),
        unselectedLabelStyle: const TextStyle(fontSize: 10, fontFamily: 'Poppins'),
        tabs: List.generate(4, (i) => Tab(
          icon: Icon(icons[i], size: 20),
          text: labels[i],
        )),
      ),
    );
  }

  Widget _buildBody() {
    if (_scanning) { return _ScanningOverlay(); }
    if (_result != null) {
      return _ResultScreen(
        result: _result!,
        onDiscard: _discardResult,
        onAdd: () => _showMealTypeSheet(_result!),
      );
    }

    switch (_activeMode) {
      case 0: return _ScanFoodMode(onCapture: _captureAndAnalyse);
      case 1: return _BarcodeMode(onScan: _mockBarcodeScan);
      case 2: return _FoodLabelMode(onSearch: _searchByText);
      case 3: return _GalleryMode(onPick: _pickFromGallery);
      default: return _ScanFoodMode(onCapture: _captureAndAnalyse);
    }
  }
}

// ─── Scanning Overlay ─────────────────────────────────────────────────────────
class _ScanningOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const OrangeLoader(size: 60),
          const SizedBox(height: 24),
          Text('Analysing your meal with AI...',
              style: AppTextStyles.h4.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text('Please wait a moment',
              style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary)),
        ]).animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1600.ms, color: AppColors.primary.withValues(alpha: 0.3)),
      ),
    );
  }
}

// ─── Mode 1 — Scan Food ───────────────────────────────────────────────────────
class _ScanFoodMode extends StatelessWidget {
  final VoidCallback onCapture;
  const _ScanFoodMode({required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Mock camera viewfinder
      Container(
        color: const Color(0xFF0A0A0A),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(children: [
                // Corner brackets
                ...[0,1,2,3].map((i) {
                  final flip = i > 1;
                  final bottom = i == 1 || i == 3;
                  return Positioned(
                    top: bottom ? null : 0,
                    bottom: bottom ? 0 : null,
                    left: flip ? null : 0,
                    right: flip ? 0 : null,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: bottom ? BorderSide.none : const BorderSide(color: AppColors.primary, width: 3),
                          bottom: bottom ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
                          left: flip ? BorderSide.none : const BorderSide(color: AppColors.primary, width: 3),
                          right: flip ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
                        ),
                      ),
                    ),
                  );
                }),
                const Center(
                  child: Text('Point camera at your food',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13,
                          fontFamily: 'Poppins')),
                ),
              ]),
            ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: AppColors.primary.withValues(alpha: 0.1)),
          ]),
        ),
      ),
      // Shutter button
      Positioned(
        bottom: 32, left: 0, right: 0,
        child: Column(children: [
          Text('Tap to analyse', style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onCapture,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.fire,
                boxShadow: [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 20, spreadRadius: 4,
                )],
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05),
              duration: 1200.ms, curve: Curves.easeInOut),
        ]),
      ),
    ]);
  }
}

// ─── Mode 2 — Barcode ─────────────────────────────────────────────────────────
class _BarcodeMode extends StatelessWidget {
  final VoidCallback onScan;
  const _BarcodeMode({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        color: const Color(0xFF0A0A0A),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 280, height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.withValues(alpha: 0.7), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(children: [
                // Red scan line animation
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _ScanLine(),
                  ),
                ),
                const Center(
                  child: Text('Align barcode within the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12,
                          fontFamily: 'Poppins')),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Text('or', style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            GFPrimaryButton(
              label: 'Simulate Barcode Scan',
              icon: Icons.qr_code_scanner_rounded,
              onTap: onScan,
              fullWidth: false,
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Align(
        alignment: Alignment(0, _anim.value * 2 - 1),
        child: Container(
          height: 2,
          color: AppColors.error.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

// ─── Mode 3 — Food Label OCR ──────────────────────────────────────────────────
class _FoodLabelMode extends StatelessWidget {
  final Future<void> Function(String) onSearch;
  final TextEditingController _ctrl = TextEditingController();

  _FoodLabelMode({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.document_scanner_rounded,
                  color: AppColors.primary, size: 48),
              SizedBox(height: 12),
              Text('Point camera at nutrition label',
                  style: TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
              SizedBox(height: 4),
              Text('or enter food name below',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12,
                      fontFamily: 'Poppins')),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'Search food name...',
              hintStyle: const TextStyle(color: AppColors.textMuted,
                  fontFamily: 'Poppins'),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.primary),
                onPressed: () => onSearch(_ctrl.text),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 16),
            ),
            onSubmitted: onSearch,
          ),
        ),
      ]),
    );
  }
}

// ─── Mode 4 — Gallery ─────────────────────────────────────────────────────────
class _GalleryMode extends StatelessWidget {
  final VoidCallback onPick;
  const _GalleryMode({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_library_rounded,
                color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 24),
          Text('Choose a Food Photo',
              style: AppTextStyles.h3.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text('Select a photo from your gallery to analyse with AI',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          GFPrimaryButton(
            label: 'Open Gallery',
            icon: Icons.photo_library_rounded,
            onTap: onPick,
            fullWidth: false,
          ),
        ]),
      ),
    );
  }
}

// ─── Result Screen ────────────────────────────────────────────────────────────
class _ResultScreen extends StatefulWidget {
  final FoodResult result;
  final VoidCallback onDiscard;
  final VoidCallback onAdd;
  const _ResultScreen({
    required this.result,
    required this.onDiscard,
    required this.onAdd,
  });

  @override
  State<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<_ResultScreen> {
  double _servings = 1.0;

  int    get _calories => (widget.result.calories * _servings).round();
  double get _protein  => widget.result.protein  * _servings;
  double get _carbs    => widget.result.carbs    * _servings;
  double get _fat      => widget.result.fat      * _servings;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Column(children: [
      // Top image area
      Expanded(
        flex: 2,
        child: Stack(fit: StackFit.expand, children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A1A),
                  AppColors.primary.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 100),
            ),
          ),
          // Floating calorie badge
          Positioned(
            top: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                )],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$_calories',
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A), fontSize: 22,
                        fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                const SizedBox(width: 4),
                const Text('kcal', style: TextStyle(
                    color: Colors.black54, fontSize: 12, fontFamily: 'Poppins')),
              ]),
            ),
          ),
          // Food name chip
          Positioned(
            bottom: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(r.name,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 16,
                      fontFamily: 'Poppins')),
            ),
          ),
        ]),
      ),
      // Bottom sheet
      Expanded(
        flex: 3,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Food name
              Text(r.name, style: AppTextStyles.h2.copyWith(color: Colors.white)),
              const SizedBox(height: 16),

              // Serving selector
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  const Text('Serving', style: TextStyle(
                      color: AppColors.textSecondary, fontFamily: 'Poppins')),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (_servings > 0.5) setState(() => _servings -= 0.5);
                    },
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove_rounded,
                          color: AppColors.primary, size: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('${_servings.toStringAsFixed(1)}x',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 16,
                            fontFamily: 'Poppins')),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _servings += 0.5),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.primary, size: 16),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Macro bars
              _MacroBar('Calories', _calories.toDouble(), 2200, Colors.grey.shade700),
              const SizedBox(height: 8),
              _MacroBar('Protein',  _protein,  150, const Color(0xFFEF5350)),
              const SizedBox(height: 8),
              _MacroBar('Carbs',    _carbs,    300, const Color(0xFF66BB6A)),
              const SizedBox(height: 8),
              _MacroBar('Fat',      _fat,      85,  const Color(0xFF42A5F5)),
              const SizedBox(height: 20),

              // Ingredients
              Text('Ingredients (kcal)', style: AppTextStyles.h4
                  .copyWith(fontSize: 14)),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: r.ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('${ing.name} ${ing.kcal}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12,
                              fontFamily: 'Poppins')),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onDiscard,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text('Discard', style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins')),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GFPrimaryButton(
                    label: 'Add to Meal Log',
                    icon: Icons.add_circle_rounded,
                    onTap: widget.onAdd,
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color  color;
  const _MacroBar(this.label, this.value, this.max, this.color);

  @override
  Widget build(BuildContext context) {
    final progress = (value / max).clamp(0.0, 1.0);
    final unit = label == 'Calories' ? 'kcal' : 'g';
    return Row(children: [
      SizedBox(width: 70,
          child: Text(label, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12,
              fontFamily: 'Poppins'))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 56,
        child: Text(
          '${value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)}$unit',
          textAlign: TextAlign.right,
          style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        ),
      ),
    ]);
  }
}
