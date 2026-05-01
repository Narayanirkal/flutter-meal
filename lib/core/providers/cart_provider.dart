import 'package:flutter/material.dart';
import 'package:meal_app/core/network/cart_repository.dart';
import 'package:meal_app/core/network/api_endpoints.dart';
import 'package:meal_app/core/services/phonepe_service.dart';

/// Local cart item — stored client-side before checkout.
class CartItem {
  final String entityType;
  final String entityId;
  final String entityName;
  final String subscriptionId;
  final String planName;
  final String price;
  final String billingCycle;
  final String startDate;
  final int? mealSizeId;

  CartItem({
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.subscriptionId,
    required this.planName,
    required this.price,
    required this.billingCycle,
    required this.startDate,
    this.mealSizeId,
  });

  double get priceValue => double.tryParse(price) ?? 0;
}

/// Provider managing the client-side cart and checkout flow.
class CartProvider with ChangeNotifier {
  final CartRepository _repository;

  CartProvider(this._repository);

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int get itemCount => _items.length;

  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.priceValue);

  // ─── Cart Operations ─────────────────────────────────────────────────────

  void addItem(CartItem item) {
    // Prevent duplicate entity+plan combos
    final exists = _items.any(
      (i) => i.entityId == item.entityId && i.subscriptionId == item.subscriptionId,
    );
    if (!exists) {
      _items.add(item);
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void removeByEntityId(String entityId) {
    _items.removeWhere((i) => i.entityId == entityId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _error = null;
    notifyListeners();
  }

  bool hasEntity(String entityId) {
    return _items.any((i) => i.entityId == entityId);
  }

  // ─── Single Buy (Direct Pay) ─────────────────────────────────────────────

  /// Initiates payment for a single entity directly (bypasses cart).
  Future<Map<String, dynamic>?> buySingle({
    required String subscriptionId,
    required String entityType,
    required String entityId,
    required String startDate,
    bool isSandbox = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paymentData = await _repository.initiateSinglePayment(
        subscriptionId: subscriptionId,
        entityType: entityType,
        entityId: entityId,
        startDate: startDate,
        redirectUrl: ApiEndpoints.paymentStatusPage,
      );

      final String? paymentUrl = paymentData['paymentUrl'];
      final String orderId = paymentData['orderId']?.toString() ?? '';
      final String? backendToken = paymentData['token']?.toString() ?? paymentData['orderToken']?.toString();
      final String? backendMerchantId = paymentData['merchantId']?.toString();

      if ((paymentUrl == null || paymentUrl.isEmpty) && backendToken == null) {
        throw Exception('Payment information not received from gateway');
      }

      // Drive the native PhonePe SDK
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
      };
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Cart Checkout ────────────────────────────────────────────────────────

  /// Checkout all cart items in a single transaction.
  Future<Map<String, dynamic>?> checkoutAll({bool isSandbox = true}) async {
    if (_items.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paymentData = await _repository.checkoutCart(
        redirectUrl: ApiEndpoints.paymentStatusPage,
      );

      final String? paymentUrl = paymentData['paymentUrl'];
      final String orderId = paymentData['orderId']?.toString() ?? '';
      final String? backendToken = paymentData['token']?.toString() ?? paymentData['orderToken']?.toString();
      final String? backendMerchantId = paymentData['merchantId']?.toString();

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

      final status = sdkResult['status'] ?? 'FAILURE';

      if (status == 'SUCCESS') {
        clearCart();
      }

      return {
        ...paymentData,
        'sdkStatus': status,
        'sdkError': sdkResult['error'],
      };
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
