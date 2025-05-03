import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_result.dart'; 
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  signupRequired, 
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _secureStorage;

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _phoneNumber;
  String? _accessToken;
  String? _refreshToken;
  String? _signupToken; 

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get phoneNumber => _phoneNumber;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get signupToken => _signupToken; 

  AuthProvider({required AuthService authService, required FlutterSecureStorage secureStorage})
      : _authService = authService,
        _secureStorage = secureStorage {
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();
    final token = await _authService.getAccessToken();
    if (token != null) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> sendOtp(String phone) async {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();

    print('[AuthProvider] Attempting to send OTP to: $phone'); 
    try {
      bool success = await _authService.sendOtp(phone);
      print('[AuthProvider] AuthService.sendOtp result: $success'); 

      if (success) {
        _phoneNumber = phone; 
        _status = AuthStatus.initial; 
        notifyListeners();
        return true;
      } else {
        _errorMessage = _authService.lastError ?? 'Failed to send OTP. Please try again.'; 
        print('[AuthProvider] OTP send failed: $_errorMessage'); 
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
        _errorMessage = 'An unexpected error occurred in AuthProvider: ${e.toString()}';
        print('[AuthProvider] Exception during sendOtp: $e'); 
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
    _signupToken = null; 
    notifyListeners();

    print('[AuthProvider] Attempting to verify OTP: $otpCode for phone: $_phoneNumber');
    AuthResult result = await _authService.verifyOtp(_phoneNumber!, otpCode);
    print('[AuthProvider] AuthService.verifyOtp result type: ${result.type}');

    switch (result.type) {
      case AuthResultType.loginSuccess:
        _accessToken = result.accessToken; 
        _refreshToken = result.refreshToken;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        print('[AuthProvider] Status set to authenticated.');
        notifyListeners();
        return true;
      case AuthResultType.signupRequired:
        _signupToken = result.signupToken; 
        _status = AuthStatus.signupRequired;
        _errorMessage = null;
        print('[AuthProvider] Status set to signupRequired. Token: $_signupToken');
        notifyListeners();
        return false; 
      case AuthResultType.failure:
        _errorMessage = result.errorMessage ?? 'OTP verification failed.';
        _status = AuthStatus.error;
        print('[AuthProvider] Status set to error: $_errorMessage');
        notifyListeners();
        return false;
    }
  }

  // Method to complete registration
  Future<bool> registerUser({
    required String firstName,
    required String? lastName,
    required String email,
    required String signupToken,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    print('[AuthProvider] Attempting registration via AuthService...');
    bool success = await _authService.registerUser(
      firstName: firstName,
      lastName: lastName,
      email: email,
      signupToken: signupToken,
    );
    print('[AuthProvider] AuthService.registerUser result: $success');

    if (success) {
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _signupToken = null; // Clear signup token on successful registration
      print('[AuthProvider] Registration successful. Status set to authenticated.');
      notifyListeners();
      return true;
    } else {
      _errorMessage = _authService.lastError ?? 'Registration failed.';
      _status = AuthStatus.error;
      print('[AuthProvider] Registration failed. Status set to error: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    print('[AuthProvider] Attempting logout'); 
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      await _authService.logout();
      print('[AuthProvider] Logout successful'); 
      _status = AuthStatus.unauthenticated;
      _phoneNumber = null;
      _errorMessage = '';
      notifyListeners();
    } catch (e) {
        print('[AuthProvider] Exception during logout: $e'); 
         _status = AuthStatus.unauthenticated; 
         _phoneNumber = null;
         _errorMessage = 'Logout failed: ${e.toString()}';
         notifyListeners();
    }
  }
}
