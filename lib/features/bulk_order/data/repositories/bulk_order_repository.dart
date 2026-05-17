import 'package:meal_app/core/network/api_endpoints.dart';
import 'package:meal_app/core/network/dio_client.dart';
import 'package:meal_app/features/bulk_order/data/models/bulk_order_config.dart';

class BulkOrderRepository {
  final DioClient _dioClient;

  BulkOrderRepository(this._dioClient);

  Future<BulkOrderConfig> fetchConfig() async {
    final response = await _dioClient.dio.get(ApiEndpoints.bulkOrderConfig);
    if (response.data['success'] == true) {
      return BulkOrderConfig.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
    }
    throw response.data['message']?.toString() ?? 'Failed to load bulk order settings';
  }

  Future<Map<String, dynamic>> fetchMenusForDelivery(String deliveryDate) async {
    final response = await _dioClient.dio.get(ApiEndpoints.bulkOrderMenus(deliveryDate));
    if (response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data'] as Map);
    }
    throw response.data['message']?.toString() ?? 'Failed to load menus';
  }

  Future<Map<String, dynamic>> quote({
    required String deliveryDate,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.bulkOrderQuote,
      data: {'deliveryDate': deliveryDate, 'items': items},
    );
    if (response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data'] as Map);
    }
    throw response.data['message']?.toString() ?? 'Quote failed';
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String deliveryDate,
    required List<Map<String, dynamic>> items,
    String? redirectUrl,
  }) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.bulkOrderInitiatePayment,
      data: {
        'deliveryDate': deliveryDate,
        'items': items,
        if (redirectUrl != null) 'redirectUrl': redirectUrl,
      },
    );
    if (response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data'] as Map);
    }
    throw response.data['message']?.toString() ?? 'Payment initiation failed';
  }
}
