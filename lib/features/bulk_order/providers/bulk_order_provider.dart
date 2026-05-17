import 'package:flutter/material.dart';
import 'package:meal_app/core/network/api_endpoints.dart';
import 'package:meal_app/core/services/network_status_service.dart';
import 'package:meal_app/core/services/phonepe_service.dart';
import 'package:meal_app/core/utils/error_handler.dart';
import 'package:meal_app/features/bulk_order/data/models/bulk_order_config.dart';
import 'package:meal_app/features/bulk_order/data/repositories/bulk_order_repository.dart';

class BulkOrderProvider with ChangeNotifier {
  final BulkOrderRepository _repository;

  BulkOrderProvider(this._repository);

  bool _loading = false;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;

  BulkOrderConfig? _config;
  BulkOrderConfig? get config => _config;

  BulkMenuOption? _deliveryMenu;
  BulkMenuOption? get deliveryMenu => _deliveryMenu;

  List<BulkMenuOption> _varietyMenus = [];
  List<BulkMenuOption> get varietyMenus => _varietyMenus;

  Map<String, dynamic>? _lastQuote;
  Map<String, dynamic>? get lastQuote => _lastQuote;

  Future<void> loadConfig() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _config = await _repository.fetchConfig();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMenusForDate(String deliveryDate) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repository.fetchMenusForDelivery(deliveryDate);
      final dm = data['delivery_menu'];
      _deliveryMenu = dm != null
          ? BulkMenuOption.fromJson(Map<String, dynamic>.from(dm as Map))
          : null;
      final list = data['variety_menus'];
      _varietyMenus = list is List
          ? list
              .map((e) => BulkMenuOption.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [];
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchQuote({
    required String deliveryDate,
    required List<Map<String, dynamic>> items,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _lastQuote = await _repository.quote(deliveryDate: deliveryDate, items: items);
      return _lastQuote;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> checkout({
    required String deliveryDate,
    required List<Map<String, dynamic>> items,
    bool isSandbox = true,
  }) async {
    if (!NetworkStatusService.instance.canAttemptApi) {
      _error = 'No internet connection. Connect to complete payment.';
      notifyListeners();
      return null;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final paymentData = await _repository.initiatePayment(
        deliveryDate: deliveryDate,
        items: items,
        redirectUrl: ApiEndpoints.paymentStatusPage,
      );
      final paymentUrl = paymentData['paymentUrl']?.toString();
      final orderId = paymentData['orderId']?.toString() ?? '';
      final merchantTransactionId = paymentData['merchantTransactionId']?.toString() ?? '';
      final backendToken = paymentData['token']?.toString() ?? paymentData['orderToken']?.toString();
      final backendMerchantId = paymentData['merchantId']?.toString();

      if ((paymentUrl == null || paymentUrl.isEmpty) && backendToken == null) {
        throw Exception('Payment information not received from gateway');
      }

      final sdkResult = await PhonePeService.pay(
        orderId: orderId,
        paymentUrl: paymentUrl,
        backendToken: backendToken,
        backendMerchantId: backendMerchantId,
        isSandbox: isSandbox,
      );

      return {
        ...paymentData,
        'sdkStatus': sdkResult['status'] ?? 'FAILURE',
        'sdkError': sdkResult['error'],
        'merchantTransactionId': merchantTransactionId,
      };
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
