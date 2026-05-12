import 'package:flutter/material.dart';
import 'package:meal_app/core/storage/local_cache.dart';
import 'package:meal_app/features/children/data/models/child_model.dart';
import 'package:meal_app/features/children/data/repositories/children_repository.dart';

class ChildrenProvider with ChangeNotifier {
  final ChildrenRepository _repository;
  final LocalCache _cache;
  static const _cacheKey = 'cache_children_v1';

  ChildrenProvider(this._repository, this._cache);

  List<ChildModel> _children = [];
  bool _isLoading = false;
  /// Stores the raw error object (DioException or String) so ErrorHandler
  /// can extract the proper server message.
  dynamic _error;

  List<ChildModel> get children => _children;
  bool get isLoading => _isLoading;
  dynamic get error => _error;

  Future<void> fetchChildren() async {
    final cached = await _cache.loadJson(_cacheKey);
    if (cached != null && _children.isEmpty) {
      final list = (cached['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(ChildModel.fromJson)
          .toList();
      if (list.isNotEmpty) {
        _children = list;
        notifyListeners();
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _children = await _repository.getChildren();
      await _cache.saveJson(_cacheKey, {
        'items': _children
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'roll_number': c.rollNumber,
                  'school_id': c.schoolId,
                  'standard_id': c.standardId,
                  'meal_size_id': c.mealSizeId,
                  'meal_time': c.mealTime,
                  'school_name': c.schoolName,
                  'standard_name': c.standardName,
                  'meal_size_name': c.mealSizeName,
                })
            .toList(),
      });
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addChild(ChildModel child) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.registerChildren([child]);
      if (success) {
        await fetchChildren();
        return true;
      }
      return false;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateChild(String id, ChildModel child) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.updateChild(id, child);
      if (success) {
        await fetchChildren();
        return true;
      }
      return false;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteChild(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteChild(id);
      if (success) {
        await fetchChildren();
        return true;
      }
      return false;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
