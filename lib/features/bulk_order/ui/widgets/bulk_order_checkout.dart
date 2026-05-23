import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meal_app/core/network/api_endpoints.dart';
import 'package:meal_app/core/utils/error_handler.dart';
import 'package:meal_app/features/bulk_order/providers/bulk_order_provider.dart';
import 'package:meal_app/features/subscription/ui/screens/payment_status_screen.dart';
import 'package:meal_app/features/subscription/ui/screens/payment_webview_screen.dart';

class BulkOrderCheckout {
  BulkOrderCheckout._();

  static Future<void> pay({
    required BuildContext context,
    required BulkOrderProvider provider,
    required String deliveryDate,
    required List<Map<String, dynamic>> items,
    required int totalMeals,
    String? summaryLines,
    bool useBundle = false,
  }) async {
    final addrErr = provider.validateDeliveryAddress(requireTime: true);
    if (addrErr != null) {
      ErrorHandler.showError(context, addrErr);
      return;
    }
    final addressPayload = provider.deliveryAddress!.toApiPayload();

    final cfg = provider.config;
    final isVarietyOrder = items.any((e) => e['bulkMealId'] != null);
    if (cfg != null && isVarietyOrder && !useBundle) {
      final cartErr = provider.validateVarietyCart(cfg, forPayment: true);
      if (cartErr != null) {
        ErrorHandler.showError(context, cartErr);
        return;
      }
    }

    if (!useBundle) {
      final quote = await provider.fetchQuote(
        deliveryDate: deliveryDate,
        items: items,
        deliveryAddress: addressPayload,
      );
      if (!context.mounted) return;
      if (quote == null) {
        if (provider.error != null) ErrorHandler.showError(context, provider.error);
        return;
      }
    }

    final addr = provider.deliveryAddress;
    final body = StringBuffer()..writeln('Delivery: $deliveryDate');
    final deliveryTime = addr?.deliveryTime?.trim();
    if (deliveryTime != null && deliveryTime.isNotEmpty) {
      body.writeln('Time: $deliveryTime');
    }
    body
      ..writeln('Address: ${addr?.formatted ?? '—'}')
      ..writeln('Total meals: $totalMeals');
    if (summaryLines != null && summaryLines.isNotEmpty) {
      body.writeln(summaryLines);
    }

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Confirm bulk order'),
        content: Text(body.toString()),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Pay'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final result = useBundle
        ? await provider.checkoutBundle(
            deliveryDate: deliveryDate,
            deliveryAddress: addressPayload,
            isSandbox: ApiEndpoints.isSandboxPayment,
          )
        : await provider.checkout(
            deliveryDate: deliveryDate,
            items: items,
            deliveryAddress: addressPayload,
            isSandbox: ApiEndpoints.isSandboxPayment,
          );
    if (!context.mounted) return;
    if (result != null) {
      final sdkStatus = result['sdkStatus']?.toString() ?? 'FAILURE';
      final txnId = result['merchantTransactionId']?.toString() ?? '';
      final orderId = result['orderId']?.toString() ?? '';
      final paymentUrl = result['paymentUrl']?.toString() ?? '';

      if (sdkStatus == 'SUCCESS') {
        if (txnId.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (_) => PaymentStatusScreen(
                txnId: txnId,
                orderId: orderId,
                orderType: 'bulk',
              ),
            ),
          );
        }
      } else {
        if (paymentUrl.isNotEmpty && txnId.isNotEmpty) {
          final webViewResult = await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => PaymentWebViewScreen(
                url: paymentUrl,
                txnId: txnId,
                orderId: orderId,
              ),
            ),
          );
          if (webViewResult == true && context.mounted) {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (_) => PaymentStatusScreen(
                  txnId: txnId,
                  orderId: orderId,
                  orderType: 'bulk',
                ),
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Payment cancelled or failed.'),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        } else {
          ErrorHandler.showError(context, result['sdkError'] ?? 'Payment failed or was cancelled.');
        }
      }
    } else if (provider.error != null) {
      ErrorHandler.showError(context, provider.error);
    }
  }
}
