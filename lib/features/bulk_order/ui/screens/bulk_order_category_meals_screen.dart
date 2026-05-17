import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/core/utils/error_handler.dart';
import 'package:meal_app/features/bulk_order/data/models/bulk_order_config.dart';
import 'package:meal_app/features/bulk_order/providers/bulk_order_provider.dart';
import 'package:meal_app/features/bulk_order/ui/widgets/bulk_order_checkout.dart';
import 'package:meal_app/features/bulk_order/ui/widgets/bulk_order_widgets.dart';
import 'package:meal_app/features/bulk_order/ui/widgets/bulk_variety_meal_card.dart';

class BulkOrderCategoryMealsScreen extends StatefulWidget {
  const BulkOrderCategoryMealsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.deliveryDate,
  });

  final String categoryId;
  final String categoryName;
  final String deliveryDate;

  @override
  State<BulkOrderCategoryMealsScreen> createState() => _BulkOrderCategoryMealsScreenState();
}

class _BulkOrderCategoryMealsScreenState extends State<BulkOrderCategoryMealsScreen> {
  static const int _maxTotalMeals = 5000;
  final Map<String, GlobalKey<BulkVarietyMealCardState>> _cardKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BulkOrderProvider>().loadMealsForCategory(widget.categoryId);
    });
  }

  GlobalKey<BulkVarietyMealCardState> _cardKey(String mealId) =>
      _cardKeys.putIfAbsent(mealId, GlobalKey<BulkVarietyMealCardState>.new);

  void _commitAll({String? exceptMealId}) {
    for (final e in _cardKeys.entries) {
      if (e.key != exceptMealId) e.value.currentState?.commitNow();
    }
  }

  bool _multiMode(BulkOrderConfig? cfg) => cfg != null && cfg.allowMultipleVarietyMeals;

  int _minForMeal(BulkOrderProvider p, String id) {
    final min = p.mealById(id)?.minOrderQuantity ?? 1;
    return min < 1 ? 1 : min;
  }

  String? _validate(BulkOrderConfig cfg, BulkOrderProvider p) {
    final lineSum = p.varietyLineSum;
    if (lineSum == 0) return 'Add portions for at least one meal.';
    if (lineSum < cfg.tierThreshold) {
      return 'Minimum order for large bulk is ${cfg.tierThreshold} meals (you have $lineSum).';
    }
    if (lineSum > _maxTotalMeals) return 'Total cannot exceed $_maxTotalMeals meals.';

    final typeCount = p.varietyMealTypeCount;
    if (!_multiMode(cfg)) {
      if (typeCount != 1) return 'Select exactly one meal type for this order.';
      return null;
    }
    if (typeCount > cfg.maxVarietyTypes) {
      return 'You can select at most ${cfg.maxVarietyTypes} different meal types.';
    }
    if (typeCount > 1) {
      for (final e in p.varietyQty.entries.where((e) => e.value > 0)) {
        final min = _minForMeal(p, e.key);
        if (e.value < min) {
          final label = p.mealById(e.key)?.items ?? 'A meal';
          return '$label needs at least $min portions when ordering multiple meals.';
        }
      }
    }
    return null;
  }

  bool _setQty(String mealId, int next, BulkOrderConfig cfg, BulkOrderProvider p) {
    if (!_multiMode(cfg)) {
      if (next <= 0) {
        p.setVarietyQty(mealId, 0);
        return true;
      }
      p.clearVarietyCart();
      p.setVarietyQty(mealId, next < cfg.tierThreshold ? cfg.tierThreshold : next);
      return true;
    }
    if (next <= 0) {
      p.setVarietyQty(mealId, 0);
      return true;
    }
    final isNew = p.varietyQtyFor(mealId) == 0;
    if (isNew && p.varietyMealTypeCount >= cfg.maxVarietyTypes) {
      ErrorHandler.showError(context, 'You can pick at most ${cfg.maxVarietyTypes} different meal types.');
      return false;
    }
    final willHaveMultiple =
        (isNew && p.varietyMealTypeCount >= 1) || (!isNew && p.varietyMealTypeCount > 1);
    final min = _minForMeal(p, mealId);
    if (willHaveMultiple && next < min) {
      final label = p.mealById(mealId)?.items ?? 'This meal';
      ErrorHandler.showError(context, '$label needs at least $min portions when ordering multiple meals.');
      return false;
    }
    p.setVarietyQty(mealId, next);
    return true;
  }

  Future<void> _pay(BulkOrderProvider p, BulkOrderConfig cfg) async {
    _commitAll();
    final err = _validate(cfg, p);
    if (err != null) {
      ErrorHandler.showError(context, err);
      return;
    }
    final items = p.varietyQty.entries
        .where((e) => e.value > 0)
        .map((e) => {'bulkMealId': e.key, 'quantity': e.value})
        .toList();
    final summary = p.varietyQty.entries
        .where((e) => e.value > 0)
        .map((e) => '${p.mealById(e.key)?.items ?? e.key} × ${e.value}')
        .join('\n');

    await BulkOrderCheckout.pay(
      context: context,
      provider: p,
      deliveryDate: widget.deliveryDate,
      items: items,
      totalMeals: p.varietyLineSum,
      summaryLines: summary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BulkOrderProvider>();
    final cfg = p.config;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final threshold = cfg?.tierThreshold ?? 50;
    final sum = p.varietyLineSum;
    final meetsMin = sum >= threshold;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: p.isLoading && p.categoryMeals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Set portions for meals in this category',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                          ),
                        ),
                        if (cfg != null && !_multiMode(cfg))
                          bulkInfoBanner(
                            isDark: isDark,
                            message: 'Only one meal type allowed for the full order.',
                            borderColor: Colors.orange.shade700,
                            backgroundColor: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
                            icon: CupertinoIcons.exclamationmark_triangle_fill,
                          ),
                        const SizedBox(height: 12),
                        if (cfg == null)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ))
                        else if (p.categoryMeals.isEmpty)
                          Text('No meals in this category.', style: TextStyle(color: Colors.orange.shade700))
                        else
                          ...p.categoryMeals.map((m) {
                            final q = p.varietyQtyFor(m.id);
                            final config = cfg;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: BulkVarietyMealCard(
                                key: _cardKey(m.id),
                                meal: m,
                                cfg: config,
                                quantity: q,
                                isDark: isDark,
                                menuImage: bulkMenuImage(m.imageUrl),
                                minQuantity: threshold,
                                singleMealOnly: !_multiMode(config),
                                onBeforeEdit: () => _commitAll(exceptMealId: m.id),
                                onQuantityChanged: (n) => _setQty(m.id, n, config, p),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                if (cfg != null)
                  Material(
                    elevation: 8,
                    color: isDark ? AppTheme.surfaceDark : Colors.white,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              meetsMin
                                  ? 'Order total: $sum meals'
                                  : '$sum meals — need ${threshold - sum} more',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: (p.isLoading || !meetsMin) ? null : () => _pay(p, cfg),
                              child: p.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Get quote & pay'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
