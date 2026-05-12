import 'package:flutter/material.dart';
import 'package:meal_app/core/storage/local_cache.dart';
import 'package:meal_app/features/home/data/models/homepage_entry.dart';
import 'package:meal_app/features/home/data/repositories/homepage_repository.dart';

class HomepageProvider with ChangeNotifier {
  final HomepageRepository _repository;
  final LocalCache _cache;
  static const _cacheKey = 'cache_homepage_entries_v1';

  bool _isLoading = false;
  String _errorMessage = '';
  List<HomepageEntry> _entries = [];

  HomepageProvider(this._repository, this._cache);

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<HomepageEntry> get entries => _entries;

  Future<void> fetchHomepageEntries() async {
    final cached = await _cache.loadJson(_cacheKey);
    if (cached != null && _entries.isEmpty) {
      final list = (cached['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(HomepageEntry.fromJson)
          .toList();
      if (list.isNotEmpty) {
        _entries = list;
        notifyListeners();
      }
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _entries = await _repository.getHomepageEntries();
      await _cache.saveJson(_cacheKey, {
        'items': _entries
            .map((e) => {
                  'id': e.id,
                  'entity_id': e.entityId,
                  'entity_name': e.entityName,
                  'name': e.name,
                  'description': e.description,
                  'display_order': e.displayOrder,
                  'is_active': e.isActive,
                })
            .toList(),
      });
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
