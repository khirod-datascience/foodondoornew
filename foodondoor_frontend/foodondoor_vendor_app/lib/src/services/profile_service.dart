import 'package:foodondoor_vendor_app/src/features/auth/services/auth_service.dart';

// Placeholder ProfileService
// Implement methods to fetch/update vendor profile data from the backend.
class ProfileService {
  final AuthService _authService;

  ProfileService(this._authService);

  Future<Map<String, dynamic>?> getVendorProfile() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        print('Error: No access token found for fetching vendor profile.');
        return null;
      }
      final response = await _authService.dio.get(
        '/api/vendor/profile/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Failed to fetch profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching vendor profile: $e');
      return null;
    }
  }

  Future<bool> updateVendorProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        print('Error: No access token found for updating vendor profile.');
        return false;
      }
      final response = await _authService.dio.put(
        '/api/vendor/profile/update/',
        data: profileData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update profile: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating vendor profile: $e');
      return false;
    }
  }
}