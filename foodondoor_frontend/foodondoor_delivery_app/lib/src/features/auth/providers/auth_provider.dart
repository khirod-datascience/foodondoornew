import 'package:flutter/material.dart';
import 'package:foodondoor_delivery_app/src/features/auth/services/auth_service.dart'; // Adjusted import path

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';
  String? _phoneNumber;

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  String? get phoneNumber => _phoneNumber;

  AuthProvider() {
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();
    final token = await _authService.getAccessToken();
    // Basic check, assumes token presence means authenticated for now
    _status = token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> sendOtp(String phone) async {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();

    bool success = await _authService.sendOtp(phone);

    if (success) {
      _phoneNumber = phone;
      _status = AuthStatus.initial;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Failed to send OTP. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otpCode) async {
    if (_phoneNumber == null) {
      _errorMessage = 'Phone number not set. Please start over.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();

    bool success = await _authService.verifyOtp(_phoneNumber!, otpCode);

    if (success) {
      _status = AuthStatus.authenticated;
      _errorMessage = '';
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Invalid OTP or verification failed. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();
    await _authService.logout();
    _status = AuthStatus.unauthenticated;
    _phoneNumber = null;
    _errorMessage = '';
    notifyListeners();
  }
}
