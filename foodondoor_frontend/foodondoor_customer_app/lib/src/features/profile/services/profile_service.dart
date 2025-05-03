import 'package:dio/dio.dart';
import 'package:foodondoor_customer_app/constants/api_constants.dart';
import 'package:foodondoor_customer_app/src/features/auth/services/auth_service.dart'; // To get the token
import 'package:foodondoor_customer_app/src/features/profile/models/customer_profile.dart';

class ProfileService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService(); // Reuse AuthService to access token

  Future<CustomerProfile?> getCustomerProfile() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      print('Error: No access token found for fetching profile.');
      return null;
    }

    try {
      final response = await _dio.get(
        ApiConstants.customerProfileUrl, // Use the correct constant
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return CustomerProfile.fromJson(response.data as Map<String, dynamic>);
      } else {
        print('Error fetching profile: Status Code ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('DioError fetching profile: ${e.response?.data ?? e.message}');
      // Handle potential 401 Unauthorized for token expiry later if needed
      if (e.response?.statusCode == 401) {
        // Optionally trigger logout or token refresh here
        await _authService.logout(); // Simple logout for now
      }
      return null;
    } catch (e) {
      print('Unexpected error fetching profile: $e');
      return null;
    }
  }

  // Add methods for updating profile later
  // Future<bool> updateCustomerProfile(CustomerProfile profile) async { ... }
}
