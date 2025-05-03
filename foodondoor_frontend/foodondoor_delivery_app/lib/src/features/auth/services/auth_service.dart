import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foodondoor_delivery_app/src/constants/api_constants.dart'; // Adjusted import path

class AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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
    try {
      final response = await _dio.post(
        ApiConstants.sendOtpUrl,
        data: {
          'phone_number': phoneNumber,
          'user_type': 'delivery_agent', // *** Important: Set user_type to delivery_agent ***
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('Error sending OTP: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Unexpected error sending OTP: $e');
      return false;
    }
  }

  /// Sends the phone number and OTP code to the backend for verification.
  /// Stores tokens on success.
  Future<bool> verifyOtp(String phoneNumber, String otpCode) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtpUrl,
        data: {
          'phone_number': phoneNumber,
          'user_type': 'delivery_agent', // *** Important: Set user_type to delivery_agent ***
          'otp_code': otpCode,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final accessToken = response.data['access'];
        final refreshToken = response.data['refresh'];

        if (accessToken != null && refreshToken != null) {
          await _storeTokens(accessToken, refreshToken);
          return true;
        } else {
          print('Error: Tokens missing in verify OTP response.');
          return false;
        }
      } else {
        print('Error verifying OTP: Status code ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      print('Error verifying OTP: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Unexpected error verifying OTP: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await clearTokens();
  }
}
