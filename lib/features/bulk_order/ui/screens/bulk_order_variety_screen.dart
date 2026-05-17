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

/// Orders at or above tier threshold: pick meals and set portions freely (no preset total).
class BulkOrderVarietyScreen extends StatefulWidget {
  const BulkOrderVarietyScreen({super.key});

  @override
  State<BulkOrderVarietyScreen> createState() => _BulkOrderVarietyScreenState();
}

class _BulkOrderVarietyScreenState extends State<BulkOrderVarietyScreen> {
  static const int _maxTotalMeals = 5000;

  String? _deliveryDate;
  final Map<String, int> _qty = {};
  final Map<String, GlobalKey<BulkVarietyMealCardState>> _cardKeys = {};
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<BulkOrderProvider>().config;
    if (cfg != null && cfg.earliestDeliveryDate.length >= 10) {
      _deliveryDate = cfg.earliestDeliveryDate;
    }
  }

  GlobalKey<BulkVarietyMealCardState> _cardKey(String mealId) =>
      _cardKeys.putIfAbsent(mealId, GlobalKey<BulkVarietyMealCardState>.new);

  void _commitAll({String? exceptMealId}) {
    for (final e in _cardKeys.entries) {
      if (e.key != exceptMealId) e.value.currentState?.commitNow();
    }
  }

  void _scheduleRefresh() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (mounted) setState(() {});
    });
  }

  int get _lineSum => _qty.values.fold(0, (a, b) => a + b);

  int get _typeCount => _qty.entries.where((e) => e.value > 0).length;

  bool get _multiMode {
    final cfg = context.read<BulkOrderProvider>().config;
    return cfg != null && cfg.allowMultipleVarietyMeals;
  }

  BulkMenuOption? _meal(BulkOrderProvider p, String id) {
    for (final m in p.varietyMenus) {
      if (m.id == id) return m;
    }
    return null;
  }

  int _minForMeal(BulkOrderProvider p, String id) {
    final min = _meal(p, id)?.minOrderQuantity ?? 1;
    return min < 1 ? 1 : min;
  }

  double? get _estimatedSubtotal {
    final p = context.read<BulkOrderProvider>();
    double sum = 0;
    var hasPrice = false;
    for (final e in _qty.entries) {
      if (e.value <= 0) continue;
      final meal = _meal(p, e.key);
      if (meal?.pricePerMeal != null) {
        hasPrice = true;
        sum += meal!.pricePerMeal! * e.value;
      }
    }
    return hasPrice ? sum : null;
  }

  String? _varietyMinMessage(BulkOrderProvider p) {
    final withMin = p.varietyMenus.where((m) => m.minOrderQuantity > 1).toList();
    if (withMin.isEmpty) return null;
    return 'When ordering multiple meals: ${withMin.map((m) => '${m.items}: min ${m.minOrderQuantity}').join(' · ')}';
  }

  String? _validate(BulkOrderConfig cfg, BulkOrderProvider p) {
    if (_lineSum == 0) return 'Add portions for at least one meal.';
    if (_lineSum < cfg.tierThreshold) {
      return 'Minimum order for large bulk is ${cfg.tierThreshold} meals (you have $_lineSum).';
    }
    if (_lineSum > _maxTotalMeals) {
      return 'Total cannot exceed $_maxTotalMeals meals.';
    }
    if (p.varietyMenus.isEmpty) {
      return 'No bulk meals available. Please try again later.';
    }

    if (!_multiMode) {
      if (_typeCount != 1) {
        return 'Select exactly one meal type for this order.';
      }
      return null;
    }

    if (_typeCount > cfg.maxVarietyTypes) {
      return 'You can select at most ${cfg.maxVarietyTypes} different meal types.';
    }

    if (_typeCount > 1) {
      for (final e in _qty.entries.where((e) => e.value > 0)) {
        final min = _minForMeal(p, e.key);
        if (e.value < min) {
          final label = _meal(p, e.key)?.items ?? 'A meal';
          return '$label needs at least $min portions when ordering multiple meals.';
        }
      }
    }

    return null;
  }

  bool _setQty(
    String mealId,
    int next,
    BulkOrderConfig cfg,
    BulkOrderProvider p, {
    bool showAlerts = true,
  }) {
    final singleOnly = !cfg.allowMultipleVarietyMeals;

    if (next <= 0) {
      _qty.remove(mealId);
      return true;
    }

    if (singleOnly) {
      if (next <= 0) {
        _qty.clear();
        return true;
      }
      _qty
        ..clear()
        ..[mealId] = next < cfg.tierThreshold ? cfg.tierThreshold : next;
      return true;
    }

    final isNew = (_qty[mealId] ?? 0) == 0;
    if (isNew && _typeCount >= cfg.maxVarietyTypes) {
      if (showAlerts) {
        ErrorHandler.showError(
          context,
          'You can pick at most ${cfg.maxVarietyTypes} different meal types.',
        );
      }
      return false;
    }

    final orderingMultiple =
        (isNew && _typeCount >= 1) || (!isNew && _typeCount > 1);
    final min = _minForMeal(p, mealId);
    if (orderingMultiple && next < min) {
      if (showAlerts) {
        final label = _meal(p, mealId)?.items ?? 'This meal';
        ErrorHandler.showError(
          context,
          '$label needs at least $min portions when ordering multiple meals.',
        );
      }
      return false;
    }

    _qty[mealId] = next;
    return true;
  }

  void _onQtyChanged(String mealId, int next, BulkOrderConfig cfg, BulkOrderProvider p) {
    if (_setQty(mealId, next, cfg, p)) _scheduleRefresh();
  }

  Future<void> _pickDate(BulkOrderConfig cfg) async {
    final ymd = await pickBulkDeliveryDate(context, cfg, _deliveryDate);
    if (ymd == null || !mounted || ymd == _deliveryDate) return;

    setState(() => _deliveryDate = ymd);
    final p = context.read<BulkOrderProvider>();
    await p.loadMenusForDate(ymd);
    if (!mounted) return;

    final validIds = p.varietyMenus.map((m) => m.id).toSet();
    final staleIds = _qty.keys.where((id) => !validIds.contains(id)).toList();
    if (staleIds.isNotEmpty) {
      setState(() {
        for (final id in staleIds) {
          _qty.remove(id);
          _cardKeys.remove(id);
        }
      });
    }
  }

  String _checkoutSummary(BulkOrderProvider p) {
    final lines = <String>[];
    for (final e in _qty.entries.where((e) => e.value > 0)) {
      final name = _meal(p, e.key)?.items ?? e.key;
      lines.add('$name × ${e.value}');
    }
    return lines.join('\n');
  }

  Future<void> _pay(BulkOrderProvider p, BulkOrderConfig cfg) async {
    if (_deliveryDate == null) {
      ErrorHandler.showError(context, 'Select a delivery date');
      return;
    }
    _commitAll();
    final err = _validate(cfg, p);
    if (err != null) {
      ErrorHandler.showError(context, err);
      return;
    }

    final items = _qty.entries
        .where((e) => e.value > 0)
        .map((e) => {'bulkMealId': e.key, 'quantity': e.value})
        .toList();

    await BulkOrderCheckout.pay(
      context: context,
      provider: p,
      deliveryDate: _deliveryDate!,
      items: items,
      totalMeals: _lineSum,
      summaryLines: _checkoutSummary(p),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BulkOrderProvider>();
    final cfg = p.config;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cfg == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Large event bulk')),
        body: const Center(child: Text('Configuration unavailable')),
      );
    }

    final meetsMin = _lineSum >= cfg.tierThreshold;
    final estimate = _estimatedSubtotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Large event bulk',
          style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimaryLight),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _multiMode
                        ? 'Add portions for each meal you want. Your order total is the sum of all portions.'
                        : 'Choose one meal and set how many portions you need.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  bulkInfoBanner(
                    isDark: isDark,
                    message: 'Minimum ${cfg.tierThreshold} meals total for this order type.',
                  ),
                  if (!_multiMode)
                    bulkInfoBanner(
                      isDark: isDark,
                      message: 'Only one meal type can be selected.',
                      borderColor: Colors.orange.shade700,
                      backgroundColor: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
                      icon: CupertinoIcons.exclamationmark_triangle_fill,
                    ),
                  if (_multiMode && _varietyMinMessage(p) != null)
                    bulkInfoBanner(isDark: isDark, message: _varietyMinMessage(p)!),
                  const SizedBox(height: 12),
                  BulkDeliveryDateTile(
                    deliveryDate: _deliveryDate,
                    onTap: () => _pickDate(cfg),
                  ),
                  const SizedBox(height: 16),
                  if (p.varietyMenus.isEmpty)
                    Text(
                      'No bulk meals available yet.',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ...p.varietyMenus.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BulkVarietyMealCard(
                        key: _cardKey(m.id),
                        meal: m,
                        cfg: cfg,
                        quantity: _qty[m.id] ?? 0,
                        isDark: isDark,
                        menuImage: bulkMenuImage(m.imageUrl),
                        minQuantity: cfg.tierThreshold,
                        singleMealOnly: !_multiMode,
                        onBeforeEdit: () => _commitAll(exceptMealId: m.id),
                        onQuantityChanged: (n) => _onQtyChanged(m.id, n, cfg, p),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Material(
            elevation: 8,
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          meetsMin
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          color: meetsMin ? Colors.green : Colors.orange.shade700,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            meetsMin
                                ? 'Order total: $_lineSum meals'
                                : '$_lineSum meals — need ${cfg.tierThreshold - _lineSum} more',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (estimate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Est. ₹${estimate.toStringAsFixed(0)} (before quote)',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                    if (_typeCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$_typeCount meal type${_typeCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
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
