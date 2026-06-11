import 'package:flutter/material.dart';
import 'package:meal_app/core/models/announcement_model.dart';
import 'package:meal_app/core/network/announcement_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meal_app/core/storage/cache_store.dart';

class AnnouncementProvider with ChangeNotifier {
  final AnnouncementRepository _repository;

  AnnouncementProvider(this._repository) {
    // Load persisted read IDs immediately on startup so the badge
    // reflects the correct unread count before the first fetch completes.
    _loadReadAnnouncements();
    _loadCachedAnnouncements();
  }

  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  DateTime? _lastFetchedAt;
  Set<String> _readAnnouncementIds = {};

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;

  List<AnnouncementModel> getAnnouncementsForLocation(String location) {
    final filtered = _announcements
        .where((a) => a.displayLocation == location || a.displayLocation == 'all')
        .where((a) => a.isActive)
        .toList();
    _sortAnnouncements(filtered);
    return filtered;
  }

  List<AnnouncementModel> getUnreadAnnouncementsForLocation(String location) {
    return getAnnouncementsForLocation(location)
        .where((a) => !_readAnnouncementIds.contains(a.id))
        .toList();
  }

  int getUnreadCountForLocation(String location) {
    return getUnreadAnnouncementsForLocation(location).length;
  }

  Future<void> _loadReadAnnouncements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_announcement_ids');
      if (readIds != null) {
        _readAnnouncementIds = readIds.toSet();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _loadCachedAnnouncements() async {
    try {
      final cached = await CacheStore.getJson('announcements_v1');
      if (cached is List) {
        final loaded = cached.map((a) => AnnouncementModel.fromJson(Map<String, dynamic>.from(a))).toList();
        _sortAnnouncements(loaded);
        _announcements = loaded;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveReadAnnouncements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'read_announcement_ids',
        _readAnnouncementIds.toList(),
      );
    } catch (_) {}
  }

  Future<void> markAsRead(String announcementId) async {
    if (!_readAnnouncementIds.contains(announcementId)) {
      _readAnnouncementIds.add(announcementId);
      await _saveReadAnnouncements();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final before = _readAnnouncementIds.length;
    for (final a in _announcements) {
      _readAnnouncementIds.add(a.id);
    }
    if (_readAnnouncementIds.length != before) {
      await _saveReadAnnouncements();
      notifyListeners();
    }
  }

  /// Fetches announcements. Pass [force] = true to always hit the network
  /// (e.g. when the user opens the bell or when a new announcement may exist).
  Future<void> fetchAnnouncements({String? location, bool force = false}) async {
    // Skip if recently fetched and not forced — avoids hammering the API
    if (!force && !shouldRefresh()) return;

    _isLoading = true;
    notifyListeners();

    try {
      // MEDIUM-03: Removed redundant _loadReadAnnouncements() call here.
      // _readAnnouncementIds is already loaded in the constructor; re-reading
      // SharedPreferences on every fetch is unnecessary disk I/O.
      final fetched = await _repository.getAnnouncements(location: location);
      _sortAnnouncements(fetched);
      _announcements = fetched;
      _lastFetchedAt = DateTime.now();

      // Keep read IDs persisted as read to avoid race conditions clearing them
      // when temporary token refreshes or partial fetches happen.
      final serialized = fetched.map((a) => a.toJson()).toList();
      await CacheStore.setJson('announcements_v1', serialized, ttl: const Duration(hours: 6));
    } catch (_) {
      // Keep old data on error — announcements are non-critical
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns true if data is stale (older than 5 minutes) or not yet loaded.
  bool shouldRefresh() {
    if (_lastFetchedAt == null) return true;
    return DateTime.now().difference(_lastFetchedAt!).inMinutes >= 5;
  }

  void _sortAnnouncements(List<AnnouncementModel> list) {
    list.sort((a, b) {
      final timeA = a.createdAt ?? a.startDate;
      final timeB = b.createdAt ?? b.startDate;
      return timeB.compareTo(timeA);
    });
  }
}
