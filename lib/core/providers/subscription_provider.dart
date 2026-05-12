import 'package:flutter/material.dart';
import 'package:meal_app/core/models/subscription_model.dart';
import 'package:meal_app/core/network/subscription_repository.dart';
import 'package:meal_app/core/storage/local_cache.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionRepository _repository;
  final LocalCache _cache;
  static const _cacheKey = 'cache_subscriptions_v1';

  SubscriptionProvider(this._repository, this._cache);

  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = false;
  String? _error;

  List<SubscriptionModel> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSubscriptions({bool force = false}) async {
    if (!force && _subscriptions.isNotEmpty) return;
    if (_isLoading) return;

    final cached = await _cache.loadJson(_cacheKey);
    if (cached != null && _subscriptions.isEmpty) {
      final list = (cached['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(SubscriptionModel.fromJson)
          .toList();
      if (list.isNotEmpty) {
        _subscriptions = list;
        notifyListeners();
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _subscriptions = await _repository.getSubscriptions();
      await _cache.saveJson(_cacheKey, {
        'items': _subscriptions
            .map((s) => {
                  'id': s.id,
                  'plan_name': s.planName,
                  'price': s.price,
                  'price_with_saturday': s.priceWithSaturday,
                  'price_without_saturday': s.priceWithoutSaturday,
                  'saturday_option_enabled': s.saturdayOptionEnabled,
                  'billing_cycle': s.billingCycle,
                  'duration_days': s.durationDays,
                  'duration_days_with_saturday': s.durationDaysWithSaturday,
                  'duration_days_without_saturday': s.durationDaysWithoutSaturday,
                  'trial_days': s.trialDays,
                  'features': s.features,
                  'display_order': s.displayOrder,
                  'is_active': s.isActive,
                  'meal_size_id': s.mealSizeId,
                })
            .toList(),
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
