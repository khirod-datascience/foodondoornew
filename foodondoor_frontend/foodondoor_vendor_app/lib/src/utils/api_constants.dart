class ApiConstants {
  // TODO: Replace with your actual backend URL
  static const String baseUrl = 'http://192.168.225.54:8000/api/';

  // Authentication Endpoints
  static const String sendOtp = 'vendor/send-otp/';
  static const String verifyOtp = 'vendor/verify-otp/';
  static const String registerVendor = 'vendor/register/'; 

  // Restaurant Endpoints
  static const String restaurantDetailsUrl = 'vendor/restaurant/';
  static const String restaurantUpdateUrl = 'vendor/restaurant/update/';

  // Order Management Endpoints
  static const String vendorOrdersUrl = 'vendor/orders/';
  // Note: IDs will be appended to these base URLs in the service
  static const String vendorOrderAcceptBaseUrl = 'vendor/orders/'; // /<id>/accept/
  static const String vendorOrderRejectBaseUrl = 'vendor/orders/'; // /<id>/reject/
  static const String vendorOrderReadyBaseUrl = 'vendor/orders/'; // /<id>/ready/

  // Vendor Profile Endpoints
  static const String vendorProfileUrl = 'vendor/profile/';
  static const String vendorProfileUpdateUrl = 'vendor/profile/update/'; // New

  // Add other constants as needed
}
