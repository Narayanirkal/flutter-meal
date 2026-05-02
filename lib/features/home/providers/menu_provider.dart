import 'package:flutter/material.dart';
import 'package:meal_app/core/network/dio_client.dart';

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

  Future<void> fetchTodayMenu() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/api/client/meals/today');
      final data = response.data;
      _isSubscribed = data['is_subscribed'] ?? false;
      if (_isSubscribed) {
        _todayMenu = data['menu'] is Map<String, dynamic> ? data['menu'] : null;
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
      final response = await _dioClient.dio.get('/api/client/meals/weekly');
      final data = response.data;
      _isSubscribed = data['is_subscribed'] ?? false;
      if (_isSubscribed) {
        _weeklyMenu = data['menu'] ?? [];
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
