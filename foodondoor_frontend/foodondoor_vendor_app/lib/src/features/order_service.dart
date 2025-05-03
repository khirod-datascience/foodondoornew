import 'package:dio/dio.dart';
import 'package:foodondoor_vendor_app/src/features/auth/services/auth_service.dart';
import 'package:foodondoor_vendor_app/src/utils/api_constants.dart';
import 'package:foodondoor_vendor_app/src/features/order_model.dart'; // Import the model

class OrderService {
  final Dio _dio;
  final AuthService _authService; // To get the token

  OrderService(this._dio, this._authService);

  Future<Options> _getOptionsWithAuthHeader() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // Fetch orders, optionally filtering by status
  Future<List<Order>> fetchOrders({String? status}) async {
    try {
      final options = await _getOptionsWithAuthHeader();
      final queryParameters = status != null && status.isNotEmpty ? {'status': status} : null;
      final response = await _dio.get(
        ApiConstants.vendorOrdersUrl,
        queryParameters: queryParameters,
        options: options,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load orders: Status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('Error fetching orders: ${e.response?.data ?? e.message}');
      rethrow; // Rethrow to be handled by the provider
    } catch (e) {
      print('Unexpected error fetching orders: $e');
      rethrow;
    }
  }

  // Accept an order
  Future<bool> acceptOrder(String orderId) async {
    try {
      final options = await _getOptionsWithAuthHeader();
      final url = '${ApiConstants.vendorOrderAcceptBaseUrl}$orderId/accept/';
      final response = await _dio.post(url, options: options);
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error accepting order $orderId: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Unexpected error accepting order $orderId: $e');
      return false;
    }
  }

  // Reject an order
  Future<bool> rejectOrder(String orderId) async {
    try {
      final options = await _getOptionsWithAuthHeader();
       final url = '${ApiConstants.vendorOrderRejectBaseUrl}$orderId/reject/';
      // Backend might require a reason? If so, add data payload.
      final response = await _dio.post(url, options: options); 
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error rejecting order $orderId: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Unexpected error rejecting order $orderId: $e');
      return false;
    }
  }

  // Mark an order as ready for pickup
  Future<bool> markOrderReady(String orderId) async {
    try {
      final options = await _getOptionsWithAuthHeader();
       final url = '${ApiConstants.vendorOrderReadyBaseUrl}$orderId/ready/';
      final response = await _dio.post(url, options: options);
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error marking order $orderId ready: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Unexpected error marking order $orderId ready: $e');
      return false;
    }
  }
}
