import 'package:dio/dio.dart';
import 'package:foodondoor_vendor_app/src/constants/api_constants.dart';
import 'package:foodondoor_vendor_app/src/features/auth/services/auth_service.dart'; // To get the token
import 'package:foodondoor_vendor_app/src/features/profile/models/vendor_profile_model.dart';

class VendorNotApprovedException implements Exception {
  @override
  String toString() => 'Your vendor account is not approved yet. Please contact support.';
}

class ProfileService {
  final Dio _dio;
  final AuthService _authService;

  ProfileService(this._dio, this._authService);

  Future<VendorProfile?> getVendorProfile() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      print('Error: No access token found for fetching vendor profile.');
      return null;
    }

    try {
      final response = await _dio.get(
        ApiConstants.vendorProfileUrl, // Endpoint for vendor profile
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return VendorProfile.fromJson(response.data as Map<String, dynamic>);
      } else {
        print('Error fetching vendor profile: Status Code ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('DioError fetching vendor profile: ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 403 &&
          (e.response?.data is Map<String, dynamic> &&
           (e.response?.data['detail'] == 'VendorProfile account is not approved.' ||
            (e.response?.data['detail']?.toString().contains('not approved') ?? false)))) {
        // Throw a custom exception for UI to handle
        throw VendorNotApprovedException();
      }
      if (e.response?.statusCode == 401) {
        await _authService.logout(); // Simple logout for now
      }
      return null;
    } catch (e) {
      print('Unexpected error fetching vendor profile: $e');
      return null;
    }
  }

  Future<VendorProfile> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Authentication token not found.');
      }
      final response = await _dio.put(
        ApiConstants.vendorProfileUpdateUrl,
        data: profileData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return VendorProfile.fromJson(response.data);
      } else {
        // Handle potential API errors (e.g., validation errors)
        throw Exception('Failed to update profile: ${response.data?['detail'] ?? response.statusMessage}');
      }
    } on DioException catch (e) {
       print("DioError updating profile: ${e.response?.data ?? e.message}");
       throw Exception('Network error updating profile: ${e.response?.data?['detail'] ?? e.message}');
    } catch (e) {
       print("Error updating profile: $e");
       throw Exception('An unexpected error occurred while updating profile.');
    }
  }
}
