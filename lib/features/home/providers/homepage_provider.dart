import 'package:flutter/material.dart';
import 'package:meal_app/features/home/data/models/homepage_entry.dart';
import 'package:meal_app/features/home/data/repositories/homepage_repository.dart';

class HomepageProvider with ChangeNotifier {
  final HomepageRepository _repository;

  bool _isLoading = false;
  String _errorMessage = '';
  List<HomepageEntry> _entries = [];
  DateTime? _lastFetchedAt;
  Future<void>? _inflightRequest;

  HomepageProvider(this._repository);

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<HomepageEntry> get entries => _entries;

  Future<void> fetchHomepageEntries({bool force = false}) async {
    final isFresh = _lastFetchedAt != null && DateTime.now().difference(_lastFetchedAt!).inSeconds < 120;
    if (!force && _entries.isNotEmpty && isFresh) return;
    if (_inflightRequest != null) return _inflightRequest;

    final request = _doFetch();
    _inflightRequest = request;
    try {
      await request;
    } finally {
      _inflightRequest = null;
    }
  }

  Future<void> _doFetch() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _entries = await _repository.getHomepageEntries();
      _lastFetchedAt = DateTime.now();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
