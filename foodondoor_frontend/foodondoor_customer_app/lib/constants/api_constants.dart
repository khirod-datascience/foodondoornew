class ApiConstants {
  static const String baseUrl = 'http://192.168.225.54:8000'; // Base backend URL
  static const String coreApiBaseUrl = '$baseUrl/api/core'; // Base for core app APIs
  static const String customerApiBaseUrl = '$baseUrl/api/customer'; // Base for customer app APIs
  // Add bases for vendor and delivery later if needed

  // Authentication Endpoints (within core app)
  static const String authBaseUrl = '$coreApiBaseUrl/auth';
  static const String sendOtpUrl = '$authBaseUrl/send-otp/';
  static const String verifyOtpUrl = '$authBaseUrl/verify-otp/';
  static const String refreshTokenUrl = '$authBaseUrl/token/refresh/';

  // Customer Specific Endpoints
  static const String customerRegisterUrl = '$customerApiBaseUrl/auth/register/'; 
  static const String customerProfileUrl = '$customerApiBaseUrl/profile/';
  // Add other customer endpoints here...
}
