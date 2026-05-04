import 'package:flutter/material.dart';
import 'package:meal_app/features/children/data/models/child_model.dart';
import 'package:meal_app/features/children/data/repositories/children_repository.dart';

class ChildrenProvider with ChangeNotifier {
  final ChildrenRepository _repository;

  ChildrenProvider(this._repository);

  List<ChildModel> _children = [];
  bool _isLoading = false;
  /// Stores the raw error object (DioException or String) so ErrorHandler
  /// can extract the proper server message.
  dynamic _error;

  List<ChildModel> get children => _children;
  bool get isLoading => _isLoading;
  dynamic get error => _error;

  Future<void> fetchChildren() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _children = await _repository.getChildren();
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
