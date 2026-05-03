import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:meal_app/core/theme/app_theme.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timed out. Please check your internet.';
        case DioExceptionType.receiveTimeout:
          return 'Server is taking too long to respond.';
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data is Map) {
            // Extract detailed errors array if present
            if (data.containsKey('errors') && data['errors'] is List && (data['errors'] as List).isNotEmpty) {
              return (data['errors'] as List).join(', ');
            }
            if (data.containsKey('message')) {
              return data['message'];
            }
          }
          return 'Server error: ${error.response?.statusCode}';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          return 'Network error. Please try again later.';
      }
    }
    return error.toString();
  }

  /// Shows an error snackbar.
  /// Always clears previous snackbars first to prevent stacking.
  static void showError(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    final messenger = ScaffoldMessenger.of(context);
    // Clear any existing snackbars to prevent stacking
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a success snackbar.
  /// Always clears previous snackbars first to prevent stacking.
  static void showSuccess(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    // Clear any existing snackbars to prevent stacking
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
