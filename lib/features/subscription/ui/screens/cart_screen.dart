import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/core/providers/cart_provider.dart';
import 'package:meal_app/core/widgets/apple_card.dart';
import 'package:meal_app/features/subscription/ui/screens/payment_status_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = cartProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cart',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearCart(context, cartProvider),
              child: Text(
                'Clear All',
                style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyCart(isDark)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(context, items[index], index, isDark, cartProvider)
                          .animate()
                          .fadeIn(delay: (index * 100).ms)
                          .slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
                _buildCheckoutBar(context, cartProvider, isDark),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.cart,
            size: 80,
            color: isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add subscriptions from the Upgrade screen',
            style: TextStyle(
              color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    int index,
    bool isDark,
    CartProvider cartProvider,
  ) {
    IconData entityIcon;
    Color entityColor;
    switch (item.entityType) {
      case 'child':
        entityIcon = CupertinoIcons.person_2_fill;
        entityColor = Colors.blue;
        break;
      case 'teacher':
        entityIcon = CupertinoIcons.book_fill;
        entityColor = Colors.green;
        break;
      case 'professional':
        entityIcon = CupertinoIcons.briefcase_fill;
        entityColor = Colors.orange;
        break;
      default:
        entityIcon = CupertinoIcons.person_fill;
        entityColor = AppTheme.primaryColor;
    }

    return Dismissible(
      key: ValueKey('${item.entityId}_${item.subscriptionId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      onDismissed: (_) => cartProvider.removeItem(index),
      child: AppleCard(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: entityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(entityIcon, color: entityColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.entityName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                        ),
                      ),
                      Text(
                        item.entityType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white38 : AppTheme.textSecondaryLight,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${item.price}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Detail rows
            _buildDetailRow('Plan', item.planName, isDark),
            _buildDetailRow('Billing', item.billingCycle, isDark),
            _buildDetailRow('Start Date', item.startDate, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CartProvider cartProvider, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${cartProvider.itemCount} ${cartProvider.itemCount == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '₹${cartProvider.totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cartProvider.isLoading
                  ? null
                  : () => _handleCheckout(context, cartProvider),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: cartProvider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.lock_fill, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Checkout & Pay',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCheckout(BuildContext context, CartProvider cartProvider) async {
    // Show loading
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(radius: 14),
              SizedBox(height: 16),
              Text('Processing checkout...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );

    final result = await cartProvider.checkoutAll(isSandbox: true);

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading

    if (!context.mounted) return;

    if (result != null) {
      final sdkStatus = result['sdkStatus']?.toString() ?? 'FAILURE';
      final txnId = result['merchantTransactionId']?.toString() ?? '';
      final orderId = result['orderId']?.toString() ?? '';

      if (sdkStatus == 'SUCCESS' || sdkStatus == 'INTERRUPTED') {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (_) => PaymentStatusScreen(txnId: txnId, orderId: orderId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment failed or was cancelled.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else if (cartProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartProvider.error!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _confirmClearCart(BuildContext context, CartProvider cartProvider) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
