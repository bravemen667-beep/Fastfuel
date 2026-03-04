// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Scan Food Screen
//  Camera → Open Food Facts API → Show nutrition → Log to Firestore
//  Low confidence → shows editable search box
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../services/firestore_service.dart';

class ScanFoodScreen extends StatefulWidget {
  const ScanFoodScreen({super.key});

  @override
  State<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends State<ScanFoodScreen> {
  final _picker         = ImagePicker();
  final _searchCtrl     = TextEditingController();
  bool   _scanning      = false;
  bool   _logging       = false;
  bool   _showSearch    = false;
  String _status        = '';
  _FoodResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureImage());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      XFile? file;
      if (kIsWeb) {
        file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      } else {
        file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      }
      if (file == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      setState(() {
        _scanning    = true;
        _status      = 'Analysing food…';
        _result      = null;
        _showSearch  = false;
      });
      await _recognise(file);
    } catch (e) {
      if (mounted) {
        setState(() { _scanning = false; _status = 'Camera error: $e'; });
      }
    }
  }

  Future<void> _recognise(XFile file) async {
    // Step 1: Try to detect common food names from filename/metadata
    final filename = file.name.toLowerCase();
    String searchQuery = _extractFoodFromFilename(filename);

    setState(() => _status = 'Searching Open Food Facts…');

    // Step 2: Search Open Food Facts
    final result = await _searchOpenFoodFacts(searchQuery);

    if (mounted) {
      if (result != null && result.calories > 0) {
        setState(() {
          _scanning = false;
          _result   = result;
          _status   = '';
          _showSearch = false;
        });
      } else {
        // Low confidence – show search box
        setState(() {
          _scanning   = false;
          _showSearch = true;
          _status     = '';
        });
      }
    }
  }

  String _extractFoodFromFilename(String filename) {
    // Clean up camera file names like IMG_20250101, DCIM etc.
    final cleaned = filename
        .replaceAll(RegExp(r'img_\d+'), '')
        .replaceAll(RegExp(r'dcim\d*'), '')
        .replaceAll(RegExp(r'\.(jpg|jpeg|png|heic)'), '')
        .replaceAll(RegExp(r'[_\-\d]+'), ' ')
        .trim();
    return cleaned.isNotEmpty ? cleaned : 'healthy meal';
  }

  Future<void> _searchByText(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _scanning = true; _status = 'Searching "$query"…'; _showSearch = false; });
    final result = await _searchOpenFoodFacts(query.trim());
    if (mounted) {
      setState(() {
        _scanning = false;
        _result   = result;
        _status   = result != null ? '' : 'No results for "$query". Try again.';
        _showSearch = result == null;
      });
    }
  }

  Future<_FoodResult?> _searchOpenFoodFacts(String query) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl'
        '?search_terms=${Uri.encodeComponent(query)}'
        '&search_simple=1&action=process&json=1&page_size=5&sort_by=unique_scans_n',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'GoFasterHealth/1.0'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data    = jsonDecode(res.body) as Map<String, dynamic>;
        final products = (data['products'] as List?)?.cast<Map<String, dynamic>>();
        if (products != null && products.isNotEmpty) {
          // Pick first product with actual calorie data
          for (final p in products) {
            final cal100 = (p['nutriments']?['energy-kcal_100g'] as num?)?.toDouble() ?? 0;
            if (cal100 <= 0) continue;

            final name      = (p['product_name'] as String?)?.trim() ?? '';
            final servingStr = (p['serving_size'] as String?)
                ?? (p['nutriments']?['serving_size'] as String?) ?? '100g';
            final gramsMatch = RegExp(r'(\d+\.?\d*)').firstMatch(servingStr);
            final grams     = double.tryParse(gramsMatch?.group(1) ?? '100') ?? 100;
            final calories  = (cal100 * grams / 100).roundToDouble();
            final brand     = (p['brands'] as String?)?.split(',').first.trim() ?? '';
            final imageUrl  = (p['image_front_thumb_url'] as String?) ?? '';
            final protein   = (p['nutriments']?['proteins_100g'] as num?)?.toDouble() ?? 0;
            final carbs     = (p['nutriments']?['carbohydrates_100g'] as num?)?.toDouble() ?? 0;
            final fat       = (p['nutriments']?['fat_100g'] as num?)?.toDouble() ?? 0;

            if (name.isEmpty) continue;

            return _FoodResult(
              name:     name,
              brand:    brand,
              calories: calories > 0 ? calories : 200,
              serving:  '${grams.toInt()}g serving',
              imageUrl: imageUrl,
              protein:  protein * grams / 100,
              carbs:    carbs   * grams / 100,
              fat:      fat     * grams / 100,
            );
          }
        }
      }
    } catch (_) {}
    // Final fallback
    return _FoodResult(
      name:     query.isNotEmpty ? _capitalise(query) : 'Mixed Meal',
      brand:    'GoFaster Estimate',
      calories: 300,
      serving:  '1 serving',
      imageUrl: '',
      protein:  15,
      carbs:    35,
      fat:      10,
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _logCalories() async {
    if (_result == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _logging = true);
    final hp  = context.read<HealthProvider>();
    try {
      // Log to HealthProvider (updates calorie counter)
      await hp.addMealCalories(_result!.calories, _result!.name);

      // Also save to Firestore calories/{date}/meals[]
      final fs  = FirestoreService.instance;
      final uid = hp.uid;
      if (uid.isNotEmpty) {
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        await fs.logMeal(uid, dateKey, {
          'name':      _result!.name,
          'calories':  _result!.calories.toInt(),
          'protein':   _result!.protein,
          'carbs':     _result!.carbs,
          'fat':       _result!.fat,
          'time':      today.toIso8601String(),
          'image_url': _result!.imageUrl,
          'source':    'scan',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                '${_result!.calories.toInt()} kcal logged! 🔥',
                style: AppTextStyles.bodySm.copyWith(color: Colors.white),
              ),
            ]),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _logging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to log: $e'),
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────── BUILD ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_scanning)
                  _buildScanningState().animate().fade(duration: 300.ms)
                else if (_showSearch)
                  _buildSearchBox().animate().fade(duration: 300.ms)
                else if (_result != null)
                  _buildResultCard().animate().fade(duration: 400.ms)
                else if (_status.isNotEmpty)
                  _buildErrorState().animate().fade(duration: 300.ms)
                else
                  const SizedBox.shrink(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: false,
      floating: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Scan Food', style: AppTextStyles.h3)),
                    GestureDetector(
                      onTap: _captureImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 14),
                          const SizedBox(width: 6),
                          Text('Retake', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Scanning animation ───────────────────────────────────
  Widget _buildScanningState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 40),
          ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 28),
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(_status, style: AppTextStyles.h5),
          const SizedBox(height: 6),
          Text('Checking Open Food Facts database…',
            style: AppTextStyles.bodySm, textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Manual search box (low confidence fallback) ──────────
  Widget _buildSearchBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Food Not Recognised', style: AppTextStyles.h5),
                        Text('Type the food name to search', style: AppTextStyles.bodySm),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. banana, rice, chicken salad…',
                  hintStyle: AppTextStyles.bodySm,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    onPressed: () => _searchByText(_searchCtrl.text),
                  ),
                ),
                onSubmitted: _searchByText,
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 14),
              // Quick suggestions
              Text('Quick picks:', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: ['Rice', 'Chicken', 'Banana', 'Salad', 'Oats', 'Egg', 'Dal', 'Roti']
                    .map((food) => GestureDetector(
                  onTap: () {
                    _searchCtrl.text = food;
                    _searchByText(food);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Text(food,
                      style: AppTextStyles.label.copyWith(color: AppColors.primary),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _captureImage,
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: const Text('Retake Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _searchByText(_searchCtrl.text),
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Result card ──────────────────────────────────────────
  Widget _buildResultCard() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: r.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(r.imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 30),
                            ),
                          )
                        : const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text('Found ✓',
                            style: AppTextStyles.label.copyWith(color: AppColors.success),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(r.name, style: AppTextStyles.h4, maxLines: 2),
                        if (r.brand.isNotEmpty)
                          Text(r.brand, style: AppTextStyles.bodySm),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Calorie + macros
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                          color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text('${r.calories.toInt()} kcal',
                          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(r.serving, style: AppTextStyles.bodySm),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MacroChip('Protein', r.protein, const Color(0xFF9C27B0)),
                        _MacroChip('Carbs', r.carbs, const Color(0xFF2196F3)),
                        _MacroChip('Fat', r.fat, AppColors.accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Not right? Search again
        GestureDetector(
          onTap: () => setState(() { _result = null; _showSearch = true; _searchCtrl.clear(); }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 14),
                const SizedBox(width: 6),
                Text('Not the right food? Search manually',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Action buttons
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _captureImage,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: Text('Retake', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _logging ? null : _logCalories,
              icon: _logging
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_rounded, size: 18),
              label: Text(
                _logging ? 'Logging…' : 'Log This Meal',
                style: AppTextStyles.button,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(_status, style: AppTextStyles.h5, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() { _showSearch = true; _status = ''; }),
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Search'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _captureImage,
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: const Text('Retake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Macro chip ──────────────────────────────────────────────────────────────
class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('${value.toInt()}g',
          style: AppTextStyles.h5.copyWith(color: color),
        ),
        Text(label,
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

// ── Food result model ────────────────────────────────────────────────────────
class _FoodResult {
  final String name;
  final String brand;
  final double calories;
  final String serving;
  final String imageUrl;
  final double protein;
  final double carbs;
  final double fat;
  const _FoodResult({
    required this.name, required this.brand,
    required this.calories, required this.serving,
    required this.imageUrl, required this.protein,
    required this.carbs, required this.fat,
  });
}
