class ApiConstants {
  static const String baseUrl = 'http://192.168.225.54:8000/api/'; // Updated to LAN IP for device access

  // Core Auth
  static const String sendOtpUrl = 'core/auth/send-otp/';
  static const String verifyOtpUrl = 'core/auth/verify-otp/';
  static const String refreshTokenUrl = 'core/auth/token/refresh/';

  // Vendor Auth & Profile
  static const String vendorRegisterUrl = 'vendor/auth/register/';
  static const String vendorProfileUrl = 'vendor/profile/';
  static const String vendorProfileUpdateUrl = 'vendor/profile/update/'; // Placeholder, might not be needed if separate restaurant

  // Vendor Restaurant Management
  static const String vendorRestaurantUrl = 'vendor/restaurant/'; // GET, PUT
  // static const String vendorRestaurantCreateUrl = 'vendor/restaurant/create/'; // Optional POST

  // Vendor Category Management
  static const String vendorCategoriesUrl = 'vendor/categories/'; // GET (List), POST (Create)
  // Note: GET (Detail), PUT, DELETE require appending '/<uuid:categoryId>/' to vendorCategoriesUrl

  // Vendor Menu Management
  static const String vendorMenuItemsUrl = 'vendor/menu-items/'; // GET and POST
  static String vendorMenuItemDetailUrl(String id) => 'vendor/menu-items/$id/'; // For GET (retrieve), PUT/PATCH (update), DELETE

  // Vendor Order Management
  static const String vendorOrdersUrl = 'vendor/orders/'; // GET (with query params like ?status=new)
  static const String vendorOrderAcceptUrl = 'vendor/orders/'; // POST with /<id>/accept/
  static const String vendorOrderReadyUrl = 'vendor/orders/'; // POST with /<id>/ready/
  static const String vendorOrderRejectUrl = 'vendor/orders/'; // POST with /<id>/reject/

}
