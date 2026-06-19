import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Client-side native Play Store update check (no backend settings needed).
class AppUpdateService {
  AppUpdateService._();

  /// Call once from the home screen after the widget tree is ready.
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      debugPrint('[AppUpdate] Querying Play Store for update availability...');
      final info = await InAppUpdate.checkForUpdate();
      debugPrint('[AppUpdate] Play Store updateAvailability: ${info.updateAvailability}');

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.flexibleUpdateAllowed) {
          debugPrint('[AppUpdate] Triggering native flexible update.');
          await InAppUpdate.startFlexibleUpdate();
        } else if (info.immediateUpdateAllowed) {
          debugPrint('[AppUpdate] Flexible update not allowed, falling back to immediate.');
          await InAppUpdate.performImmediateUpdate();
        }
      }
    } catch (e) {
      debugPrint('[AppUpdate] Native check failed: $e');
      developer.log(
        'In-app update check failed: $e',
        name: 'AppUpdateService',
      );
    }
  }
}
