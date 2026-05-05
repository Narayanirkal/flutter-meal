import 'package:meal_app/core/network/dio_client.dart';
import 'package:meal_app/core/network/api_endpoints.dart';

/// Repository for server-side cart operations.
/// All cart data lives on the backend — the client never stores cart locally.
class CartRepository {
  final DioClient _dioClient;

  CartRepository(this._dioClient);

  /// GET /api/client/cart — Fetch the current active cart from the server.
  Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.viewCart);
      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      // If 404 (no cart), return empty
      return {};
    }
  }

  /// POST /api/client/cart/add — Add an entity to the server cart.
  Future<Map<String, dynamic>> addToCart({
    required String subscriptionId,
    required String entityType,
    required String entityId,
    required bool includeSaturday,
    required String startDate,
  }) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.addToCart,
      data: {
        'subscriptionId': subscriptionId,
        'entityType': entityType,
        'entityId': entityId,
        'includeSaturday': includeSaturday,
        'startDate': startDate,
      },
    );
    if (response.data['success'] == true) {
      return response.data;
    }
    throw response.data['message']?.toString() ?? 'Failed to add item to cart';
  }

  /// PATCH /api/client/cart/item/{itemId} — Update meal start date before checkout.
  Future<void> updateCartItemStartDate({
    required int itemId,
    required String startDate,
  }) async {
    final response = await _dioClient.dio.patch(
      ApiEndpoints.removeCartItem(itemId),
      data: {'startDate': startDate},
    );
    if (response.data['success'] != true) {
      throw response.data['message']?.toString() ?? 'Failed to update start date';
    }
  }

  /// DELETE /api/client/cart/item/{itemId} — Remove one item from server cart.
  Future<bool> removeCartItem(int itemId) async {
    final response = await _dioClient.dio.delete(
      ApiEndpoints.removeCartItem(itemId),
    );
    return response.data['success'] == true;
  }

  /// DELETE /api/client/cart/clear — Clear all items from the active cart.
  Future<bool> clearCart() async {
    final response = await _dioClient.dio.delete(ApiEndpoints.clearCart);
    return response.data['success'] == true;
  }

  /// POST /api/client/payment/checkout-cart — Checkout entire cart.
  Future<Map<String, dynamic>> checkoutCart({String? redirectUrl}) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.checkoutCart,
      data: {
        if (redirectUrl != null) 'redirectUrl': redirectUrl,
      },
    );
    if (response.data['success'] == true) {
      return response.data['data'] ?? response.data;
    }
    throw response.data['message']?.toString() ?? 'Cart checkout failed';
  }
}
