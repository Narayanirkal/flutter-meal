import 'package:flutter/material.dart';
import 'package:meal_app/core/network/dio_client.dart';
import 'package:meal_app/core/network/api_endpoints.dart';

class MenuProvider with ChangeNotifier {
  final DioClient _dioClient;
  
  MenuProvider(this._dioClient);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  Map<String, dynamic>? _todayMenu;
  Map<String, dynamic>? get todayMenu => _todayMenu;

  List<dynamic> _weeklyMenu = [];
  List<dynamic> get weeklyMenu => _weeklyMenu;

  List<dynamic> _subscriptionSummary = [];
  List<dynamic> get subscriptionSummary => _subscriptionSummary;

  String? _error;
  String? get error => _error;

  String _normalizeDateKey(dynamic raw) {
    final value = raw?.toString() ?? '';
    if (value.isEmpty) return '';
    return value.contains('T') ? value.split('T').first : value;
  }

  List<String> _extractNutrition(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return [];
  }

  Future<void> fetchTodayMenu() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final mealResponse = await _dioClient.dio.get('/api/client/meals/today');
      final data = mealResponse.data;
      _isSubscribed = data['is_subscribed'] ?? false;
      if (_isSubscribed) {
        if (data['menu'] is Map<String, dynamic>) {
          final menu = Map<String, dynamic>.from(data['menu']);
          List<String> nutritionPoints = [];
          try {
            final nutritionResponse = await _dioClient.dio.get(ApiEndpoints.clientMenuNutritionToday);
            final nutritionData = nutritionResponse.data;
            nutritionPoints = _extractNutrition(nutritionData['data']?['nutrition_points']);
          } catch (_) {
            // Keep menu working even if nutrition endpoint fails temporarily.
          }
          menu['nutrition_points'] = nutritionPoints;
          _todayMenu = menu;
        } else {
          _todayMenu = null;
        }
        _subscriptionSummary = data['subscription_summary'] ?? [];
      } else {
        _todayMenu = null;
        _subscriptionSummary = [];
      }
    } catch (e) {
      if (e.toString().contains('403')) {
        _isSubscribed = false;
        _todayMenu = null;
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeeklyMenu() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final mealResponse = await _dioClient.dio.get('/api/client/meals/weekly');
      final data = mealResponse.data;
      _isSubscribed = data['is_subscribed'] ?? false;
      if (_isSubscribed) {
        final weeklyMenus = (data['menu'] as List?) ?? [];
        final nutritionByDate = <String, List<String>>{};
        try {
          final nutritionResponse = await _dioClient.dio.get(ApiEndpoints.clientMenuNutritionWeekly);
          final nutritionData = nutritionResponse.data;
          final nutritionRows = (nutritionData['data'] as List?) ?? [];
          for (final row in nutritionRows) {
            if (row is Map<String, dynamic>) {
              final menuDate = _normalizeDateKey(row['menu_date']);
              if (menuDate.isNotEmpty) {
                nutritionByDate[menuDate] = _extractNutrition(row['nutrition_points']);
              }
            }
          }
        } catch (_) {
          // Keep weekly menu working even if nutrition endpoint fails temporarily.
        }

        _weeklyMenu = weeklyMenus.map((entry) {
          if (entry is Map<String, dynamic>) {
            final menu = Map<String, dynamic>.from(entry);
            final menuDate = _normalizeDateKey(menu['menu_date']);
            menu['nutrition_points'] = nutritionByDate[menuDate] ?? <String>[];
            return menu;
          }
          return entry;
        }).toList();
        _subscriptionSummary = data['subscription_summary'] ?? [];
      } else {
        _weeklyMenu = [];
      }
    } catch (e) {
      if (e.toString().contains('403')) {
        _isSubscribed = false;
        _weeklyMenu = [];
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
