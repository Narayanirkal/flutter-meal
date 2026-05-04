import 'package:flutter/material.dart';
import 'package:meal_app/features/profile/data/models/profile_models.dart';
import 'package:meal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:meal_app/core/utils/error_handler.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileRepository _repository;

  ProfileProvider(this._repository);

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
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getTeacherProfile(),
        _repository.getProfessionalProfile(),
        _repository.getProfileStatus(),
      ]);

      _teacherProfile = results[0] as TeacherProfileModel?;
      _professionalProfile = results[1] as ProfessionalProfileModel?;
      _profileStatus = results[2] as Map<String, dynamic>?;
    } catch (e) {
      _error = e;
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
