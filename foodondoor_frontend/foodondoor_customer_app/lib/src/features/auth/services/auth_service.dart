import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foodondoor_customer_app/constants/api_constants.dart';
import 'package:foodondoor_customer_app/src/features/auth/models/auth_result.dart'; 

class AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _lastError; // Add field to store last error message

  String? get lastError => _lastError; // Getter for last error

  // --- Token Storage ---
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'accessToken', value: accessToken);
    await _secureStorage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'accessToken');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refreshToken');
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
  }

  // --- API Calls ---

  /// Sends a request to the backend to send an OTP to the given phone number.
  Future<bool> sendOtp(String phoneNumber) async {
    _lastError = null; // Reset last error
    final url = ApiConstants.sendOtpUrl;
    final data = {
      'phone_number': phoneNumber,
      'user_type': 'customer', // Hardcoded for customer app
    };

    print('[AuthService] Sending OTP request to: $url');
    print('[AuthService] Request data: $data');

    try {
      final response = await _dio.post(url, data: data);
      print('[AuthService] Received response status code: ${response.statusCode}');
      print('[AuthService] Received response data: ${response.data}');

      // Check for successful response (e.g., status code 200 or 201)
      // The backend currently returns a generic success message, so we rely on status code
      final bool success = response.statusCode == 200 || response.statusCode == 201;
      if (!success) {
         _lastError = 'Backend returned status code: ${response.statusCode}';
         print('[AuthService] ${_lastError}');
      }
      return success;

    } on DioException catch (e) {
      // Handle Dio specific errors
      _lastError = 'DioException during sendOtp: ${e.message}';
      print('[AuthService] ${_lastError}');
      if (e.response != null) {
        print('[AuthService] DioException Response data: ${e.response?.data}');
        print('[AuthService] DioException Response headers: ${e.response?.headers}');
        print('[AuthService] DioException Response status code: ${e.response?.statusCode}');
         _lastError = 'DioException during sendOtp: ${e.response?.data ?? e.message} (Status: ${e.response?.statusCode})';
      } else {
        // Error occured setting up or sending the request
        print('[AuthService] DioException Error: ${e.message}');
        _lastError = 'DioException during sendOtp: ${e.message}';
      }
      print('[AuthService] DioException type: ${e.type}');
      return false;
    } catch (e) {
      // Handle other potential errors
       _lastError = 'Unexpected error sending OTP: ${e.toString()}';
      print('[AuthService] ${_lastError}');
      return false;
    }
  }

  /// Sends the phone number and OTP code to the backend for verification.
  /// Stores tokens on success.
  Future<AuthResult> verifyOtp(String phoneNumber, String otpCode) async {
    _lastError = null; // Reset last error
    final url = ApiConstants.verifyOtpUrl;
    final data = {
      'phone_number': phoneNumber,
      'user_type': 'customer',
      'otp_code': otpCode,
    };

    print('[AuthService] Sending verify OTP request to: $url');
    print('[AuthService] Request data: $data');

    try {
      final response = await _dio.post(url, data: data);
      print('[AuthService] Received response status code: ${response.statusCode}');
      print('[AuthService] Received response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // Check if signup is required
        if (responseData.containsKey('signup_required') && responseData['signup_required'] == true) {
          final signupToken = responseData['signup_token'] as String?;
          if (signupToken != null) {
            print('[AuthService] Signup required. Storing signup token.');
            // Store signup token temporarily if needed (e.g., in provider state)
            // For now, just indicate signup is needed
            return AuthResult(type: AuthResultType.signupRequired, signupToken: signupToken);
          } else {
            print('[AuthService] Signup required but signup_token missing.');
            return AuthResult(type: AuthResultType.failure, errorMessage: 'Signup token missing.');
          }
        }
        // --- Existing Login Flow --- 
        else if (responseData.containsKey('access') && responseData.containsKey('refresh')) {
          final accessToken = responseData['access'] as String?;
          final refreshToken = responseData['refresh'] as String?;

          if (accessToken != null && refreshToken != null) {
            await _storeTokens(accessToken, refreshToken);
            print('[AuthService] Login successful. Tokens stored.');
            return AuthResult(type: AuthResultType.loginSuccess, accessToken: accessToken, refreshToken: refreshToken);
          } else {
             print('[AuthService] Tokens missing in verify OTP response.');
            return AuthResult(type: AuthResultType.failure, errorMessage: 'Tokens missing in response.');
          }
        } else {
          // Handle cases where neither signup nor login tokens are present (unexpected)
          print('[AuthService] Unexpected response format.');
           return AuthResult(type: AuthResultType.failure, errorMessage: 'Unexpected response format.');
        }
      } else {
        print('[AuthService] Verify OTP failed with status code: ${response.statusCode}');
        return AuthResult(type: AuthResultType.failure, errorMessage: 'Verification failed.');
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      _lastError = 'DioException during verifyOtp: ${e.message}';
      print('[AuthService] ${_lastError}');
      if (e.response != null) {
        print('[AuthService] DioException Response data: ${e.response?.data}');
        print('[AuthService] DioException Response headers: ${e.response?.headers}');
        print('[AuthService] DioException Response status code: ${e.response?.statusCode}');
        _lastError = 'DioException during verifyOtp: ${e.response?.data ?? e.message} (Status: ${e.response?.statusCode})';
      } else {
        // Error occured setting up or sending the request
        print('[AuthService] DioException Error: ${e.message}');
        _lastError = 'DioException during verifyOtp: ${e.message}';
      }
      print('[AuthService] DioException type: ${e.type}');
      return AuthResult(type: AuthResultType.failure, errorMessage: e.message);
    } catch (e) {
      // Handle other potential errors
       _lastError = 'Unexpected error verifying OTP: ${e.toString()}';
      print('[AuthService] ${_lastError}');
      return AuthResult(type: AuthResultType.failure, errorMessage: 'An unexpected error occurred.');
    }
  }

  // Method to register a new user after OTP verification
  Future<bool> registerUser({
    required String firstName,
    required String? lastName, // Can be optional
    required String email,
    required String signupToken,
  }) async {
    _lastError = null; // Clear previous error
    try {
      print('[AuthService] Attempting registration...');
      final response = await _dio.post(
        ApiConstants.customerRegisterUrl, // Use the correct endpoint directly
        data: {
          'first_name': firstName,
          'last_name': lastName ?? '', // Send empty string if null
          'email': email,
          'signup_token': signupToken,
        },
      );

      print('[AuthService] Registration response status: ${response.statusCode}');
      print('[AuthService] Registration response data: ${response.data}');

      if (response.statusCode == 201 && response.data != null) {
        final accessToken = response.data['access_token'] as String?;
        final refreshToken = response.data['refresh_token'] as String?;

        if (accessToken != null && refreshToken != null) {
          await _secureStorage.write(key: 'accessToken', value: accessToken);
          await _secureStorage.write(key: 'refreshToken', value: refreshToken);
          print('[AuthService] Registration successful. Tokens stored.');
          return true;
        } else {
          _lastError = 'Registration completed but tokens were missing in response.';
          print('[AuthService] Error: $_lastError');
          return false;
        }
      } else {
        _lastError = _extractErrorMessage(response.data) ?? 'Registration failed with status: ${response.statusCode}';
        print('[AuthService] Error: $_lastError');
        return false;
      }
    } on DioException catch (e) {
      _lastError = _handleDioError(e);
      print('[AuthService] DioException during registration: $_lastError');
      return false;
    } catch (e) {
      _lastError = 'An unexpected error occurred during registration: ${e.toString()}';
      print('[AuthService] Exception during registration: $e');
      return false;
    }
  }

  String? _extractErrorMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // Check for common error keys
      if (responseData.containsKey('error')) {
        return responseData['error'] as String?;
      }
      if (responseData.containsKey('detail')) {
        return responseData['detail'] as String?;
      }
      // Check for field-specific errors (less likely for this endpoint but good practice)
      if (responseData.entries.isNotEmpty) {
          // Combine field errors if necessary
          return responseData.entries.map((e) => '${e.key}: ${e.value}').join('; ');
      }
    }
    return null; // Could not extract a specific error message
  }

  String _handleDioError(DioException e) {
    print("[AuthService] DioException Type: ${e.type}");
    print("[AuthService] DioException Error: ${e.error}");
    print("[AuthService] DioException Message: ${e.message}");
    print("[AuthService] DioException Response: ${e.response?.data}");

    String errorMessage;
    if (e.response != null) {
      // Error with a response from the server (4xx, 5xx)
      errorMessage = _extractErrorMessage(e.response?.data) ?? 'Server error: ${e.response?.statusCode}';
    } else {
      // Error without a response (network issue, connection refused, etc.)
      errorMessage = 'Network error: ${e.message ?? 'Could not connect to server.'} (Type: ${e.type})';
    }
    _lastError = errorMessage;
    return errorMessage;
  }

  // Optional: Add refresh token logic here later if needed
  // Future<bool> refreshToken() async { ... }

  // Placeholder for logout logic
  Future<void> logout() async {
    print('[AuthService] Clearing tokens on logout.');
    await clearTokens();
    // Potentially notify backend about logout (if implemented)
  }
}
