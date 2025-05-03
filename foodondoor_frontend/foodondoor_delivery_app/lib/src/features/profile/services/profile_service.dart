import 'package:dio/dio.dart';
import 'package:foodondoor_delivery_app/src/constants/api_constants.dart';
import 'package:foodondoor_delivery_app/src/features/auth/services/auth_service.dart'; // To get the token
import 'package:foodondoor_delivery_app/src/features/profile/models/delivery_agent_profile.dart';

class ProfileService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  Future<DeliveryAgentProfile?> getDeliveryAgentProfile() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      print('Error: No access token found for fetching delivery agent profile.');
      return null;
    }

    try {
      final response = await _dio.get(
        '${ApiConstants.apiBaseUrl}/delivery/profile/', // Endpoint for delivery agent profile
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return DeliveryAgentProfile.fromJson(response.data as Map<String, dynamic>);
      } else {
        print('Error fetching delivery agent profile: Status Code ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('DioError fetching delivery agent profile: ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401) {
        await _authService.logout(); // Simple logout for now
      }
      return null;
    } catch (e) {
      print('Unexpected error fetching delivery agent profile: $e');
      return null;
    }
  }

  // Add methods for updating profile/location later
}
