import 'package:flutter/material.dart';
import 'package:meal_app/core/network/api_endpoints.dart';
import 'package:meal_app/core/services/phonepe_service.dart';
import 'package:meal_app/core/utils/error_handler.dart';
import 'package:meal_app/features/bulk_order/data/models/bulk_delivery_address.dart';
import 'package:meal_app/features/quick_service/data/repositories/quick_service_repository.dart';

class QuickServiceProvider with ChangeNotifier {
  final QuickServiceRepository _repository;
  QuickServiceProvider(this._repository);

  bool _loading = false;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;

  Map<String, dynamic>? _oneDayConfig;
  Map<String, dynamic>? get oneDayConfig => _oneDayConfig;

  Map<String, dynamic>? _todayMenu;
  Map<String, dynamic>? get todayMenu => _todayMenu;

  List<dynamic> _categories = [];
  List<dynamic> get categories => _categories;

  List<dynamic> _items = [];
  List<dynamic> get items => _items;

  final Map<String, int> _cartQty = {};
  Map<String, int> get cartQty => Map.unmodifiable(_cartQty);

  int get cartItemCount => _cartQty.values.fold(0, (a, b) => a + b);

  BulkDeliveryAddress? _address;
  BulkDeliveryAddress? get address => _address;

  void setAddress(BulkDeliveryAddress? value) {
    _address = value;
    notifyListeners();
  }

  Future<BulkDeliveryAddress?> loadSavedDeliveryAddress() async {
    try {
      final data = await _repository.getSavedDeliveryAddress();
      if (data == null) return null;
      final address = BulkDeliveryAddress(
        stateId: int.tryParse('${data['state_id'] ?? data['stateId']}') ?? 0,
        cityId: int.tryParse('${data['city_id'] ?? data['cityId']}') ?? 0,
        addressLine: data['address_line']?.toString() ?? data['addressLine']?.toString() ?? '',
        pincode: data['pincode']?.toString(),
        stateName: data['state_name']?.toString() ?? data['stateName']?.toString(),
        cityName: data['city_name']?.toString() ?? data['cityName']?.toString(),
        deliveryTime: data['delivery_time']?.toString() ?? data['deliveryTime']?.toString(),
      );
      if (address.isComplete) {
        _address = address;
        notifyListeners();
        return address;
      }
    } catch (_) {}
    return null;
  }

  Future<void> loadOneDayConfig() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _oneDayConfig = await _repository.getOneDayLunchConfig();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setTodayMenu(Map<String, dynamic>? menu) {
    _todayMenu = menu;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _repository.getSpecialCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadItems(String categoryId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repository.getSpecialItems(categoryId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCartFromServer() async {
    try {
      final data = await _repository.getSpecialCart();
      final items = data['items'];
      _cartQty.clear();
      if (items is List) {
        for (final row in items) {
          if (row is Map) {
            final id = row['item_id']?.toString() ?? row['special_dish_item_id']?.toString();
            final qty = int.tryParse('${row['quantity']}') ?? 0;
            if (id != null && id.isNotEmpty && qty > 0) _cartQty[id] = qty;
          }
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  void setCartQty(String itemId, int qty) {
    if (qty <= 0) {
      _cartQty.remove(itemId);
    } else {
      _cartQty[itemId] = qty;
    }
    notifyListeners();
    _persistCart();
  }

  Future<void> _persistCart() async {
    try {
      await _repository.saveSpecialCart({
        'items': _cartQty.entries.map((e) => {'item_id': e.key, 'quantity': e.value}).toList(),
      });
    } catch (_) {}
  }

  Map<String, dynamic> _addressPayload() {
    final a = _address!;
    return {
      'state_id': a.stateId,
      'city_id': a.cityId,
      'address_line': a.addressLine,
      if (a.pincode != null) 'pincode': a.pincode,
      if (a.deliveryTime != null && a.deliveryTime!.trim().isNotEmpty) 'delivery_time': a.deliveryTime!.trim(),
    };
  }

  Future<Map<String, dynamic>?> payOneDayLunch({
    required String deliveryType,
    required int quantity,
    required int mealSizeId,
    required String deliveryTime,
  }) async {
    if (_address == null || !_address!.isComplete) {
      _error = 'Please complete delivery address';
      notifyListeners();
      return null;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final paymentData = await _repository.initiateOneDayLunchPayment({
        'delivery_type': deliveryType,
        'quantity': quantity,
        'meal_size_id': mealSizeId,
        'delivery_time': deliveryTime,
        'delivery_address': _addressPayload(),
        'redirectUrl': ApiEndpoints.paymentStatusPage,
      });
      return _runPhonePe(paymentData);
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> paySpecialDishes() async {
    if (_address == null || !_address!.isComplete) {
      _error = 'Please complete delivery address';
      notifyListeners();
      return null;
    }
    if (_cartQty.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final paymentData = await _repository.initiateSpecialDishPayment({
        'items': _cartQty.entries.map((e) => {'item_id': e.key, 'quantity': e.value}).toList(),
        'delivery_address': _addressPayload(),
        'redirectUrl': ApiEndpoints.paymentStatusPage,
      });
      final result = await _runPhonePe(paymentData);
      if (result != null && result['sdkStatus'] == 'SUCCESS') {
        _cartQty.clear();
        await _persistCart();
      }
      return result;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> _runPhonePe(Map<String, dynamic> paymentData) async {
    final paymentUrl = paymentData['paymentUrl']?.toString();
    final orderId = paymentData['orderId']?.toString() ?? '';
    final merchantTransactionId = paymentData['merchantTransactionId']?.toString() ?? '';
    final backendToken = paymentData['token']?.toString() ?? paymentData['orderToken']?.toString();
    final backendMerchantId = paymentData['merchantId']?.toString();

    if ((paymentUrl == null || paymentUrl.isEmpty) && backendToken == null) {
      _error = 'Payment information not received from gateway';
      return null;
    }

    final sdkResult = await PhonePeService.pay(
      orderId: orderId,
      paymentUrl: paymentUrl,
      backendToken: backendToken,
      backendMerchantId: backendMerchantId,
      isSandbox: ApiEndpoints.isSandboxPayment,
    );
    final status = sdkResult['status']?.toString() ?? 'FAILURE';
    if (status != 'SUCCESS') {
      _error = sdkResult['error']?.toString() ?? 'Payment was not completed';
    }
    return {
      'sdkStatus': status,
      'merchantTransactionId': merchantTransactionId,
      'orderId': orderId,
      'paymentUrl': paymentUrl ?? '',
      'error': sdkResult['error']?.toString(),
    };
  }
}
