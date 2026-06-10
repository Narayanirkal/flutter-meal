import 'package:flutter/material.dart';
import 'package:meal_app/core/models/referral_model.dart';
import 'package:meal_app/core/network/referral_repository.dart';
import 'package:meal_app/core/storage/cache_store.dart';

class ReferralProvider with ChangeNotifier {
  final ReferralRepository _repository;

  ReferralProvider(this._repository) {
    _loadCachedRewards();
  }

  List<ReferralRewardModel> _rewards = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReferralRewardModel> get rewards => _rewards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadCachedRewards() async {
    try {
      final cached = await CacheStore.getJson('referral_rewards');
      if (cached is List) {
        _rewards = cached
            .map((e) => ReferralRewardModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchRewards() async {
    if (_rewards.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _rewards = await _repository.getReferralRewards();
      await CacheStore.setJson(
        'referral_rewards',
        _rewards.map((e) => e.toJson()).toList(),
        ttl: const Duration(hours: 6),
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _rewards.isNotEmpty ? null : e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> applyCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.applyReferralCode(code);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> allocateMeals({
    required int rewardId,
    required String entityType,
    required String entityId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.allocateReferralMeals(
        rewardId: rewardId,
        entityType: entityType,
        entityId: entityId,
      );
      if (success) {
        await fetchRewards();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
