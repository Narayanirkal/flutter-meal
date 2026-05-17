import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/core/widgets/apple_card.dart';
import 'package:meal_app/features/bulk_order/data/models/bulk_order_config.dart';

/// Per-meal quantity card for large (50+) bulk orders. No preset order total required.
class BulkVarietyMealCard extends StatefulWidget {
  const BulkVarietyMealCard({
    super.key,
    required this.meal,
    required this.cfg,
    required this.quantity,
    required this.isDark,
    required this.menuImage,
    required this.minQuantity,
    required this.singleMealOnly,
    required this.onBeforeEdit,
    required this.onQuantityChanged,
  });

  final BulkMenuOption meal;
  final BulkOrderConfig cfg;
  final int quantity;
  final bool isDark;
  final Widget menuImage;
  final int minQuantity;
  final bool singleMealOnly;
  final VoidCallback onBeforeEdit;
  final ValueChanged<int> onQuantityChanged;

  @override
  State<BulkVarietyMealCard> createState() => BulkVarietyMealCardState();
}

class BulkVarietyMealCardState extends State<BulkVarietyMealCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textForQty(widget.quantity));
    _controller.addListener(_onTextChanged);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant BulkVarietyMealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity && !_focusNode.hasFocus) {
      final nextText = _textForQty(widget.quantity);
      if (_controller.text != nextText) {
        _controller.text = nextText;
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  String _textForQty(int q) => q > 0 ? '$q' : '';

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  /// True when the field value differs from the last applied quantity.
  bool get _hasPendingInput {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return widget.quantity != 0;
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return true;
    return parsed != widget.quantity;
  }

  void commitNow() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      if (widget.quantity != 0) widget.onQuantityChanged(0);
      return;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      _controller.text = _textForQty(widget.quantity);
      return;
    }
    if (parsed != widget.quantity) widget.onQuantityChanged(parsed);
  }

  void _applyAndDismiss() {
    if (!_hasPendingInput) {
      _focusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    commitNow();
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) setState(() {});
  }

  void _adjust(int delta) {
    commitNow();
    FocusManager.instance.primaryFocus?.unfocus();
    final base = widget.quantity > 0 ? widget.quantity : 0;
    int next;
    if (widget.singleMealOnly) {
      if (base == 0 && delta > 0) {
        next = widget.minQuantity;
      } else {
        next = base + delta;
      }
    } else {
      next = base + delta;
    }
    widget.onQuantityChanged(next <= 0 ? 0 : next);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meal;
    final q = widget.quantity;
    final selected = q > 0;
    final isDark = widget.isDark;
    final multi = widget.cfg.allowMultipleVarietyMeals && !widget.singleMealOnly;

    return AppleCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
        ),
        padding: selected ? const EdgeInsets.all(2) : EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.menuImage,
            if (m.imageUrl != null && m.imageUrl!.isNotEmpty) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.items,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (m.pricePerMeal != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '₹${m.pricePerMeal!.toStringAsFixed(2)} per meal',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (multi && m.minOrderQuantity > 1) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Min ${m.minOrderQuantity} when ordering multiple meals',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$q',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              multi
                  ? 'Enter portions, then tap ✓ or Done on the keyboard'
                  : (selected
                      ? 'Portions for this meal (min ${widget.minQuantity})'
                      : 'Tap + to select this meal'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Remove one',
                  onPressed: selected ? () => _adjust(-1) : null,
                  icon: Icon(
                    CupertinoIcons.minus_circle,
                    color: selected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.35),
                  ),
                ),
                if (multi)
                  SizedBox(
                    width: 80,
                    child: Listener(
                      onPointerDown: (_) => widget.onBeforeEdit(),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                          hintText: '0',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onSubmitted: (_) => _applyAndDismiss(),
                        onEditingComplete: _applyAndDismiss,
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(minWidth: 48),
                    alignment: Alignment.center,
                    child: Text(
                      selected ? '$q' : '—',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                IconButton(
                  tooltip: multi ? 'Add one' : 'Select meal',
                  onPressed: () => _adjust(multi ? 1 : 0),
                  icon: const Icon(
                    CupertinoIcons.plus_circle_fill,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (multi)
                  IconButton(
                    tooltip: 'Apply quantity',
                    onPressed: _hasPendingInput ? _applyAndDismiss : null,
                    icon: Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: _hasPendingInput
                          ? Colors.green.shade600
                          : Colors.grey.withValues(alpha: 0.45),
                      size: 30,
                    ),
                  ),
              ],
            ),
            if (selected && m.pricePerMeal != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Subtotal ₹${(m.pricePerMeal! * q).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
