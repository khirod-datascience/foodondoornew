import 'dart:convert'; // For jsonEncode if needed later

class User {
  final String? id;
  final String phoneNumber;
  // Add other user fields if needed (e.g., name)

  User({this.id, required this.phoneNumber});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'phone_number': phoneNumber,
    };
  }
}

class VendorProfile {
  final String? id; // Assuming backend provides an ID
  final String companyName;
  final String email;
  final User user; // Added nested user object
  // Add other fields as needed from your backend model (e.g., address, etc.)

  VendorProfile({
    this.id,
    required this.companyName,
    required this.email,
    required this.user, // Added to constructor
  });

  // Factory constructor for creating a new VendorProfile instance from a map.
  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    // Handle potentially null user data from backend
    final userData = json['user'] as Map<String, dynamic>?;

    return VendorProfile(
      id: json['id'] as String?,
      companyName: json['company_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      // Create User object from nested data, provide default if null
      user: userData != null 
            ? User.fromJson(userData) 
            : User(phoneNumber: ''), // Provide a default empty User if key is missing
      // Map other fields here
    );
  }

  // Method for converting a VendorProfile instance to a map (useful for sending data).
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'company_name': companyName,
      'email': email,
      'user': user.toJson(), // Include user data
      // Add other fields here
    };
  }
}
