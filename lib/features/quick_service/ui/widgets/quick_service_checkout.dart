import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/core/utils/error_handler.dart';
import 'package:meal_app/features/bulk_order/providers/bulk_order_provider.dart';
import 'package:meal_app/features/bulk_order/ui/widgets/bulk_order_address_section.dart';
import 'package:meal_app/features/quick_service/providers/quick_service_provider.dart';
import 'package:meal_app/features/subscription/ui/screens/payment_status_screen.dart';

class QuickServiceCheckout {
  QuickServiceCheckout._();

  static void _openStatusScreen(
    BuildContext context, {
    required String txnId,
    required String orderId,
    required String orderType,
  }) {
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        builder: (_) => PaymentStatusScreen(
          txnId: txnId,
          orderId: orderId,
          orderType: orderType,
        ),
      ),
    );
  }

  static Future<void> payOneDayLunch(
    BuildContext context, {
    required String deliveryType,
    int quantity = 1,
    bool skipAddressPrompt = false,
  }) async {
    final bulk = context.read<BulkOrderProvider>();
    await bulk.loadSavedDeliveryAddress();

    if (skipAddressPrompt) {
      final err = bulk.validateDeliveryAddress();
      if (err != null) {
        ErrorHandler.showError(context, err);
        return;
      }
      await _completeOneDayLunch(
        context,
        deliveryType: deliveryType,
        quantity: quantity,
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressSheet(
        title: deliveryType == 'today' ? 'Order for today' : 'Order for tomorrow',
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _completeOneDayLunch(
      context,
      deliveryType: deliveryType,
      quantity: quantity,
    );
  }

  static Future<void> _completeOneDayLunch(
    BuildContext context, {
    required String deliveryType,
    required int quantity,
  }) async {
    final bulk = context.read<BulkOrderProvider>();
    final provider = context.read<QuickServiceProvider>();
    provider.setAddress(bulk.deliveryAddress);

    final result = await provider.payOneDayLunch(
      deliveryType: deliveryType,
      quantity: quantity,
    );
    if (!context.mounted) return;

    if (result != null) {
      final txnId = result['merchantTransactionId']?.toString() ?? '';
      final orderId = result['orderId']?.toString() ?? '';
      if (txnId.isNotEmpty) {
        _openStatusScreen(
          context,
          txnId: txnId,
          orderId: orderId,
          orderType: 'one_day_lunch',
        );
        return;
      }
    }
    if (provider.error != null) {
      ErrorHandler.showError(context, provider.error!);
    }
  }

  static Future<void> paySpecialDishes(
    BuildContext context, {
    bool skipAddressPrompt = false,
  }) async {
    final bulk = context.read<BulkOrderProvider>();
    await bulk.loadSavedDeliveryAddress();

    if (skipAddressPrompt) {
      final err = bulk.validateDeliveryAddress();
      if (err != null) {
        ErrorHandler.showError(context, err);
        return;
      }
      await _completeSpecialDishes(context);
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressSheet(
        title: 'Confirm delivery address',
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _completeSpecialDishes(context);
  }

  static Future<void> _completeSpecialDishes(BuildContext context) async {
    final bulk = context.read<BulkOrderProvider>();
    final provider = context.read<QuickServiceProvider>();
    provider.setAddress(bulk.deliveryAddress);

    final result = await provider.paySpecialDishes();
    if (!context.mounted) return;

    if (result != null) {
      final txnId = result['merchantTransactionId']?.toString() ?? '';
      final orderId = result['orderId']?.toString() ?? '';
      if (txnId.isNotEmpty) {
        _openStatusScreen(
          context,
          txnId: txnId,
          orderId: orderId,
          orderType: 'special_dish',
        );
        return;
      }
    }
    if (provider.error != null) {
      ErrorHandler.showError(context, provider.error!);
    }
  }
}

class _AddressSheet extends StatelessWidget {
  const _AddressSheet({
    required this.title,
    required this.onConfirm,
  });

  final String title;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter where we should deliver your order.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const BulkOrderAddressSection(),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final err = context.read<BulkOrderProvider>().validateDeliveryAddress();
                  if (err != null) {
                    ErrorHandler.showError(context, err);
                    return;
                  }
                  onConfirm();
                },
                child: const Text('Continue to payment', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
