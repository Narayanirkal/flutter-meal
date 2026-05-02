import 'package:flutter/material.dart';
import 'package:meal_app/core/network/cart_repository.dart';
import 'package:meal_app/core/network/api_endpoints.dart';
import 'package:meal_app/core/services/phonepe_service.dart';

/// Server-side cart item — mirrors the backend response.
class CartItem {
  final int id; // server-side cart item id (for delete)
  final String entityName;
  final String entityType;
  final String planName;
  final double unitPrice;
  final String? startDate;
  final String? entityId;
  final String? subscriptionId;

  CartItem({
    required this.id,
    required this.entityName,
    required this.entityType,
    required this.planName,
    required this.unitPrice,
    this.startDate,
    this.entityId,
    this.subscriptionId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      entityName: json['entity_name']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? '',
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      startDate: json['start_date']?.toString(),
      entityId: json['entity_id']?.toString(),
      subscriptionId: json['subscription_id']?.toString(),
    );
  }
}

/// Provider managing the SERVER-SIDE cart.
/// All operations hit the backend — no local-only state.
class CartProvider with ChangeNotifier {
  final CartRepository _repository;

  CartProvider(this._repository);

  List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  String? _cartId;
  String? get cartId => _cartId;

  double _totalAmount = 0;
  double get totalAmount => _totalAmount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int get itemCount => _items.length;

  // ─── Fetch cart from server ─────────────────────────────────────────────────

  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getCart();

      // Parse the cart response
      final cart = data['cart'];
      if (cart != null) {
        _cartId = cart['id']?.toString();
        _totalAmount = double.tryParse(cart['total_amount']?.toString() ?? '0') ?? 0;
      } else {
        _cartId = null;
        _totalAmount = 0;
      }

      // Parse items
      final List itemsList = data['items'] ?? [];
      _items = itemsList.map((json) => CartItem.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      _items = [];
      _totalAmount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Add item to server cart ────────────────────────────────────────────────

  Future<bool> addItem({
    required String subscriptionId,
    required String entityType,
    required String entityId,
    required String startDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.addToCart(
        subscriptionId: subscriptionId,
        entityType: entityType,
        entityId: entityId,
        startDate: startDate,
      );

      // Refresh cart from server to get updated state
      await fetchCart();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Remove item from server cart ───────────────────────────────────────────

  Future<bool> removeItem(int cartItemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.removeCartItem(cartItemId);
      // Refresh cart from server
      await fetchCart();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Clear entire cart on server ────────────────────────────────────────────

  Future<bool> clearCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.clearCart();
      _items = [];
      _totalAmount = 0;
      _cartId = null;
    } catch (e) {
      _error = _extractErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _error == null;
  }

  // ─── Check if entity is already in cart ─────────────────────────────────────

  bool hasEntity(String entityId) {
    return _items.any((i) => i.entityId == entityId);
  }

  // ─── Cart Checkout via PhonePe SDK ──────────────────────────────────────────

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
        // Clear local state after successful payment
        _items = [];
        _totalAmount = 0;
        _cartId = null;
      }

      return {
        ...paymentData,
        'sdkStatus': status,
        'sdkError': sdkResult['error'],
      };
    } catch (e) {
      _error = _extractErrorMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Extracts a clean error message from exceptions.
  String _extractErrorMessage(Object e) {
    final raw = e.toString();
    // Try to extract 'message' from DioException response
    if (raw.contains('message')) {
      final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(raw);
      if (match != null) return match.group(1)!;
    }
    return raw.replaceAll('Exception:', '').trim();
  }
}
