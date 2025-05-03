class ApiConstants {
  static const String baseUrl = 'http://192.168.225.54:8000';
  static const String apiBaseUrl = '$baseUrl/api/v1'; // Assuming v1 prefix

  // Authentication Endpoints
  static const String sendOtpUrl = '$apiBaseUrl/send-otp/';
  static const String verifyOtpUrl = '$apiBaseUrl/verify-otp/';
  static const String refreshTokenUrl = '$apiBaseUrl/token/refresh/'; // Placeholder
}
