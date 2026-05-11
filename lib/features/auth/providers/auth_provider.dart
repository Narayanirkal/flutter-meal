import 'package:flutter/material.dart';
import 'package:meal_app/features/auth/data/repositories/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }
enum AuthMode { login, register }

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  AuthState _state = AuthState.initial;
  AuthMode _authMode = AuthMode.login;
  String _errorMessage = '';
  String _phoneNumber = '';
  String _username = '';
  bool _isProfileLoading = false;

  AuthProvider(this._authRepository) {
    _checkAuthStatus();
  }

  AuthState get state => _state;
  AuthMode get authMode => _authMode;
  String get errorMessage => _errorMessage;
  String get phoneNumber => _phoneNumber;
  String get username => _username;
  bool get isProfileLoading => _isProfileLoading;

  void setAuthMode(AuthMode mode) {
    _authMode = mode;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _checkAuthStatus() async {
    // Stay on [initial] until we know the session — so the splash can paint.
    // [loading] is reserved for user-triggered actions (OTP, etc.).
    final isAuthenticated = await _authRepository.isAuthenticated();
    if (isAuthenticated) {
      _phoneNumber = await _authRepository.getPhoneNumber() ?? '';
      _username = await _authRepository.getUsername() ?? '';
      await refreshMeProfile(silent: true);
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // ─── LOGIN FLOW ────────────────────────────────────────────────────────────

  Future<bool> loginSendOtp(String phone) async {
    _state = AuthState.loading;
    _errorMessage = '';
    _phoneNumber = phone;
    notifyListeners();

    try {
      final success = await _authRepository.loginSendOtp(phone);
      if (success) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to send OTP';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginVerifyOtp(String code) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _authRepository.loginVerifyOtp(_phoneNumber, code);
      if (success) {
        _username = await _authRepository.getUsername() ?? '';
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid OTP';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // ─── REGISTER FLOW ────────────────────────────────────────────────────────

  Future<bool> registerSendOtp(String phone, String username) async {
    _state = AuthState.loading;
    _errorMessage = '';
    _phoneNumber = phone;
    _username = username;
    notifyListeners();

    try {
      final success = await _authRepository.registerSendOtp(phone, username);
      if (success) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to send OTP';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerVerifyOtp(String code) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _authRepository.registerVerifyOtp(_phoneNumber, _username, code);
      if (success) {
        _username = await _authRepository.getUsername() ?? _username;
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid OTP or registration failed';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // ─── LOGOUT ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    await _authRepository.logout();
    
    _state = AuthState.unauthenticated;
    _phoneNumber = '';
    _username = '';
    _authMode = AuthMode.login;
    notifyListeners();
  }

  Future<void> refreshMeProfile({bool silent = false}) async {
    if (!silent) {
      _isProfileLoading = true;
      notifyListeners();
    }
    try {
      final liveUsername = await _authRepository.fetchCurrentUsername();
      if (liveUsername != null && liveUsername.trim().isNotEmpty) {
        _username = liveUsername.trim();
      }
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }
}
