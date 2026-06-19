import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:meal_app/core/network/api_endpoints.dart';

/// Backend-controlled in-app update service.
///
/// The update is only triggered when you set a higher `minimum_build_number`
/// in the `app_settings` table on your backend.  Regular Play Store releases
/// won't bother users unless you explicitly flip the switch.
class AppUpdateService {
  AppUpdateService._();

  /// Call once from the home screen after the widget tree is ready.
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // 1. Get the minimum required build number from backend.
      final minimumBuild = await _fetchMinimumBuildNumber();
      debugPrint('[AppUpdate] Backend minimum_build_number: $minimumBuild');

      if (minimumBuild <= 0) {
        debugPrint('[AppUpdate] No minimum version set, skipping.');
        return; // No minimum set — no forced update.
      }

      // 2. Get current app's build number.
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      debugPrint('[AppUpdate] Current build number: $currentBuild');

      // 3. Compare: only force update if current build is below minimum.
      if (currentBuild >= minimumBuild) {
        debugPrint('[AppUpdate] App is up to date, no action needed.');
        return;
      }

      debugPrint('[AppUpdate] App is outdated ($currentBuild < $minimumBuild). Triggering mandatory update.');

      // 4. Use Play Store's native immediate update.
      final info = await InAppUpdate.checkForUpdate();
      debugPrint('[AppUpdate] Play Store updateAvailability: ${info.updateAvailability}');
      debugPrint('[AppUpdate] Play Store immediateAllowed: ${info.immediateUpdateAllowed}');

      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        debugPrint('[AppUpdate] Play Store update not available yet.');
      }
    } catch (e) {
      debugPrint('[AppUpdate] ERROR: $e');
      developer.log(
        'In-app update check failed: $e',
        name: 'AppUpdateService',
      );
    }
  }

  /// Fetches the minimum required build number from the backend.
  /// Returns 0 if not set or on any error.
  static Future<int> _fetchMinimumBuildNumber() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio.get(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.minimumAppVersion}',
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return data['data']?['minimum_build_number'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('[AppUpdate] Failed to fetch minimum version: $e');
      return 0;
    }
  }
}
