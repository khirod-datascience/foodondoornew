import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:foodondoor_vendor_app/src/constants/api_constants.dart';
import 'package:foodondoor_vendor_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:foodondoor_vendor_app/src/features/auth/services/auth_service.dart';

class RestaurantService {
  final Dio _dio;
  final AuthService _authService;

  RestaurantService(this._dio, this._authService);

  /// Fetches the restaurant details for the currently authenticated vendor.
  /// Assumes the backend provides a single endpoint for the vendor's restaurant.
  Future<Restaurant?> getRestaurantDetails() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      print('Error: No access token found for fetching restaurant details.');
      return null;
    }

    try {
      final response = await _dio.get(
        ApiConstants.vendorRestaurantUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (kDebugMode) {
          print('[RestaurantService] Fetched restaurant data: ${response.data}');
        }
        // Assuming the response data is the JSON object for the restaurant
        // It might be nested, e.g., response.data['restaurant']
        // Adjust .fromJson call based on actual backend response structure
        return Restaurant.fromJson(response.data);
      } else {
        if (kDebugMode) {
          print('[RestaurantService] Failed to fetch restaurant details. Status: ${response.statusCode}, Data: ${response.data}');
        }
        return null;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[RestaurantService] DioError fetching restaurant: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      }
      // Specific handling for 404 might be needed if a vendor *might not* have a restaurant yet
      if (e.response?.statusCode == 404) {
        print('[RestaurantService] Restaurant not found (404). Vendor might need to create one.');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[RestaurantService] Unexpected error fetching restaurant: $e');
      }
      return null;
    }
  }

  /// Updates the restaurant details.
  /// Assumes the backend uses the same base URL (/api/vendor/restaurant/)
  /// and expects a PATCH request to update the vendor's associated restaurant.
  Future<Restaurant?> updateRestaurantDetails(Map<String, dynamic> updateData) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    try {
      final response = await _dio.patch(
        ApiConstants.vendorRestaurantUrl,
        data: updateData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (kDebugMode) {
          print('[RestaurantService] Updated restaurant data: ${response.data}');
        }
        return Restaurant.fromJson(response.data);
      } else {
        if (kDebugMode) {
          print('[RestaurantService] Failed to update restaurant. Status: ${response.statusCode}, Data: ${response.data}');
        }
        return null;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[RestaurantService] DioError updating restaurant: ${e.response?.statusCode} - ${e.response?.data ?? e.message}');
      }
      if (e.response?.statusCode == 401) {
        await _authService.logout(); // Handle unauthorized
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[RestaurantService] Unexpected error updating restaurant: $e');
      }
      return null;
    }
  }

  // TODO: Add methods for uploading logo if needed (likely using FormData)
}
