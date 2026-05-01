import 'package:meal_app/core/network/dio_client.dart';
import 'package:meal_app/core/network/api_endpoints.dart';

/// Repository for cart operations — add items, view cart, checkout.
class CartRepository {
  final DioClient _dioClient;

  CartRepository(this._dioClient);

  /// Initiate a single entity payment (adds to order).
  Future<Map<String, dynamic>> initiateSinglePayment({
    required String subscriptionId,
    required String entityType,
    required String entityId,
    required String startDate,
    String? redirectUrl,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.initiatePayment,
        data: {
          'subscriptionId': subscriptionId,
          'entityType': entityType,
          'entityId': entityId,
          'startDate': startDate,
          if (redirectUrl != null) 'redirectUrl': redirectUrl,
        },
      );
      if (response.data['success'] == true) {
        return response.data['data'] ?? response.data;
      }
      throw response.data['message']?.toString() ?? 'Payment initiation failed';
    } catch (e) {
      rethrow;
    }
  }

  /// Checkout entire cart — pay total for all entities in one transaction.
  Future<Map<String, dynamic>> checkoutCart({String? redirectUrl}) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }
}
