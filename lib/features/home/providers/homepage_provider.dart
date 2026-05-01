import 'package:flutter/material.dart';
import 'package:meal_app/features/home/data/models/homepage_entry.dart';
import 'package:meal_app/features/home/data/repositories/homepage_repository.dart';

class HomepageProvider with ChangeNotifier {
  final HomepageRepository _repository;

  bool _isLoading = false;
  String _errorMessage = '';
  List<HomepageEntry> _entries = [];

  HomepageProvider(this._repository);

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<HomepageEntry> get entries => _entries;

  Future<void> fetchHomepageEntries() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _entries = await _repository.getHomepageEntries();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
