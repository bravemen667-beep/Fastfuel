import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  String _selectedMealType = 'Breakfast';
  final _searchCtrl = TextEditingController();
  bool _isLogging = false;
  final List<_FoodItem> _selected = [];

  static const _mealTypes = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
  static const _suggestions = [
    _FoodItem('Roti (2 pcs)', 160, Icons.set_meal_rounded, AppColors.accent),
    _FoodItem('Dal (1 cup)', 120, Icons.soup_kitchen_rounded, AppColors.primary),
    _FoodItem('Rice (1 cup)', 200, Icons.rice_bowl_rounded, AppColors.warning),
    _FoodItem('Chicken (100g)', 165, Icons.restaurant_rounded, AppColors.error),
    _FoodItem('Salad', 45, Icons.eco_rounded, AppColors.success),
    _FoodItem('Banana', 89, Icons.apple_rounded, AppColors.accent),
    _FoodItem('Paneer (50g)', 142, Icons.egg_rounded, AppColors.primary),
    _FoodItem('Curd (1 cup)', 98, Icons.local_drink_rounded, Color(0xFF2196F3)),
  ];

  int get _totalCals => _selected.fold(0, (sum, item) => sum + item.calories);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _logMeal() async {
    if (_selected.isEmpty) return;
    setState(() => _isLogging = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLogging = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success),
            const SizedBox(width: 10),
            Text('$_selectedMealType logged · $_totalCals kcal',
              style: AppTextStyles.bodySm.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Text('Log Meal', style: AppTextStyles.h4),
        actions: [
          if (_selected.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: AppGradients.fire,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text('$_totalCals kcal',
                style: AppTextStyles.buttonSm,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Meal type selector
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _mealTypes.length,
              itemBuilder: (_, i) {
                final selected = _mealTypes[i] == _selectedMealType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMealType = _mealTypes[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        gradient: selected ? AppGradients.fire : null,
                        color: selected ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: selected ? Colors.transparent : AppColors.border),
                      ),
                      child: Center(
                        child: Text(_mealTypes[i], style: AppTextStyles.buttonSm.copyWith(
                          color: selected ? Colors.white : AppColors.textSecondary,
                        )),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Search food items...',
                  hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Selected items
          if (_selected.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected (${_selected.length})', style: AppTextStyles.h5),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _selected.map((item) => GestureDetector(
                      onTap: () => setState(() => _selected.remove(item)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: item.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.name, style: AppTextStyles.label.copyWith(color: item.color)),
                            const SizedBox(width: 6),
                            Icon(Icons.close_rounded, size: 12, color: item.color),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border),
                ],
              ),
            ),
          ],
          // Food list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (_, i) {
                final food = _suggestions[i];
                final isAdded = _selected.contains(food);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isAdded ? food.color.withValues(alpha: 0.08) : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isAdded ? food.color.withValues(alpha: 0.3) : AppColors.border,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: food.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(food.icon, color: food.color, size: 20),
                    ),
                    title: Text(food.name, style: AppTextStyles.h5),
                    subtitle: Text('${food.calories} kcal', style: AppTextStyles.bodySm),
                    trailing: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isAdded) { _selected.remove(food); }
                          else { _selected.add(food); }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          gradient: isAdded ? AppGradients.fire : null,
                          color: isAdded ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: isAdded ? Colors.transparent : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          isAdded ? Icons.check_rounded : Icons.add_rounded,
                          color: isAdded ? Colors.white : AppColors.textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Log button
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: GFPrimaryButton(
                label: _isLogging ? 'Logging...' : 'Log $_selectedMealType · $_totalCals kcal',
                icon: Icons.check_circle_rounded,
                onTap: _isLogging ? null : _logMeal,
                loading: _isLogging,
              ),
            ),
        ],
      ),
    );
  }
}

class _FoodItem {
  final String name;
  final int calories;
  final IconData icon;
  final Color color;
  const _FoodItem(this.name, this.calories, this.icon, this.color);
}
