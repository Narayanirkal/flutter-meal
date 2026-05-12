import 'package:flutter/material.dart';
import 'package:meal_app/core/storage/local_cache.dart';
import 'package:meal_app/features/profile/data/models/profile_models.dart';
import 'package:meal_app/features/profile/data/repositories/profile_repository.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileRepository _repository;
  final LocalCache _cache;
  static const _cacheKey = 'cache_profiles_v1';

  ProfileProvider(this._repository, this._cache);

  TeacherProfileModel? _teacherProfile;
  ProfessionalProfileModel? _professionalProfile;
  Map<String, dynamic>? _profileStatus;
  
  bool _isLoading = false;
  /// Stores the raw error object (DioException or String) so ErrorHandler
  /// can extract the proper server message instead of a raw toString().
  dynamic _error;

  TeacherProfileModel? get teacherProfile => _teacherProfile;
  ProfessionalProfileModel? get professionalProfile => _professionalProfile;
  Map<String, dynamic>? get profileStatus => _profileStatus;
  bool get isLoading => _isLoading;
  dynamic get error => _error;

  Future<void> fetchProfiles({bool force = false}) async {
    if (!force && _teacherProfile != null && _professionalProfile != null) return;
    if (_isLoading) return;

    bool hasCachedProfile = false;
    final cached = await _cache.loadJson(_cacheKey);
    if (cached != null &&
        (_teacherProfile == null || _professionalProfile == null || _profileStatus == null)) {
      final teacher = cached['teacher_profile'];
      final professional = cached['professional_profile'];
      if (_teacherProfile == null && teacher is Map<String, dynamic>) {
        _teacherProfile = TeacherProfileModel.fromJson(teacher);
      }
      if (_professionalProfile == null && professional is Map<String, dynamic>) {
        _professionalProfile = ProfessionalProfileModel.fromJson(professional);
      }
      if (_profileStatus == null && cached['profile_status'] is Map<String, dynamic>) {
        _profileStatus = Map<String, dynamic>.from(cached['profile_status'] as Map);
      }
      hasCachedProfile = _teacherProfile != null || _professionalProfile != null;
      notifyListeners();
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getTeacherProfile(),
        _repository.getProfessionalProfile(),
        _repository.getProfileStatus(),
      ]);

      final fetchedTeacher = results[0] as TeacherProfileModel?;
      final fetchedProfessional = results[1] as ProfessionalProfileModel?;
      final fetchedStatus = results[2] as Map<String, dynamic>?;

      // Repositories return `null` both for "not found" and transient/offline failures.
      // Preserve already-hydrated cached profiles when fetch returns null.
      if (fetchedTeacher != null || _teacherProfile == null) {
        _teacherProfile = fetchedTeacher;
      }
      if (fetchedProfessional != null || _professionalProfile == null) {
        _professionalProfile = fetchedProfessional;
      }
      if (fetchedStatus != null || _profileStatus == null) {
        _profileStatus = fetchedStatus;
      }

      final existingCache = await _cache.loadJson(_cacheKey);
      final existingTeacher = existingCache != null && existingCache['teacher_profile'] is Map
          ? Map<String, dynamic>.from(existingCache['teacher_profile'] as Map)
          : null;
      final existingProfessional = existingCache != null && existingCache['professional_profile'] is Map
          ? Map<String, dynamic>.from(existingCache['professional_profile'] as Map)
          : null;
      final existingStatus = existingCache != null && existingCache['profile_status'] is Map
          ? Map<String, dynamic>.from(existingCache['profile_status'] as Map)
          : null;
      final teacherForCache = _teacherProfile == null
          ? null
          : {
              ..._teacherProfile!.toJson(),
              'id': _teacherProfile!.id,
            };
      final professionalForCache = _professionalProfile == null
          ? null
          : {
              ..._professionalProfile!.toJson(),
              'id': _professionalProfile!.id,
            };
      await _cache.saveJson(_cacheKey, {
        'teacher_profile': teacherForCache ?? existingTeacher,
        'professional_profile': professionalForCache ?? existingProfessional,
        'profile_status': _profileStatus ?? existingStatus,
      });
    } catch (e) {
      // Keep using cached profile silently in offline mode.
      _error = hasCachedProfile ? null : e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveTeacherProfile(TeacherProfileModel profile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.saveTeacherProfile(
        profile, 
        isUpdate: _teacherProfile != null
      );
      if (success) {
        await fetchProfiles(force: true);
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

  Future<bool> deleteTeacherProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteTeacherProfile();
      if (success) {
        _teacherProfile = null;
        await fetchProfiles(force: true);
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

  Future<bool> saveProfessionalProfile(ProfessionalProfileModel profile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.saveProfessionalProfile(
        profile, 
        isUpdate: _professionalProfile != null
      );
      if (success) {
        await fetchProfiles(force: true);
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

  Future<bool> deleteProfessionalProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteProfessionalProfile();
      if (success) {
        _professionalProfile = null;
        await fetchProfiles(force: true);
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
