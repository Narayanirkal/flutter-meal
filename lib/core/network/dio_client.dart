import 'package:dio/dio.dart';
import 'package:meal_app/core/network/api_endpoints.dart';
import 'package:meal_app/core/storage/secure_storage.dart';

class DioClient {
  late Dio _dio;
  final SecureStorage _secureStorage;

  DioClient(this._secureStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await _secureStorage.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          // Token might be expired, try to refresh
          final newAccessToken = await _refreshToken();
          if (newAccessToken != null) {
            // Update the original request with the new token
            e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            try {
              // Retry the request
              final response = await _dio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (retryError) {
              return handler.next(e);
            }
          } else {
            // Refresh failed, clear tokens and let the UI handle the logout
            await _secureStorage.clearTokens();
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return null;

      // Note: We use a separate Dio instance to avoid infinite loops in interceptors
      final tokenDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final response = await tokenDio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        // Assume API returns similar structure to login
        final accessToken = response.data['data']['accessToken'];
        final newRefreshToken = response.data['data']['refreshToken'];
        await _secureStorage.saveTokens(accessToken, newRefreshToken);
        return accessToken;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Dio get dio => _dio;
}
