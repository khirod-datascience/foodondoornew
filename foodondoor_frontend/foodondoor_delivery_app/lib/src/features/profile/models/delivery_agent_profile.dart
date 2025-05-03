import 'package:flutter/foundation.dart';

enum VehicleType {
  bicycle,
  motorcycle,
  scooter,
  car,
  unknown // Default or fallback
}

// Helper to convert string to VehicleType enum
VehicleType _vehicleTypeFromString(String? typeString) {
  switch (typeString?.toLowerCase()) {
    case 'bicycle':
      return VehicleType.bicycle;
    case 'motorcycle':
      return VehicleType.motorcycle;
    case 'scooter':
      return VehicleType.scooter;
    case 'car':
      return VehicleType.car;
    default:
      return VehicleType.unknown;
  }
}

// Helper to convert VehicleType enum to string
String _vehicleTypeToString(VehicleType type) {
  return type.toString().split('.').last;
}

@immutable
class DeliveryAgentProfile {
  final String id;
  final String? email;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String? fcmToken;
  final VehicleType vehicleType;
  final String? vehicleDetails;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool isAvailable;
  final String? profilePictureUrl; // Assuming backend sends URL
  final bool isActive;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeliveryAgentProfile({
    required this.id,
    this.email,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    this.fcmToken,
    required this.vehicleType,
    this.vehicleDetails,
    this.currentLatitude,
    this.currentLongitude,
    required this.isAvailable,
    this.profilePictureUrl,
    required this.isActive,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryAgentProfile.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse double
    double? parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return DeliveryAgentProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fcmToken: json['fcm_token'] as String?,
      vehicleType: _vehicleTypeFromString(json['vehicle_type'] as String?),
      vehicleDetails: json['vehicle_details'] as String?,
      currentLatitude: parseDouble(json['current_latitude']),
      currentLongitude: parseDouble(json['current_longitude']),
      isAvailable: json['is_available'] as bool? ?? false, // Provide default
      profilePictureUrl: json['profile_picture'] as String?, // Assuming URL field name
      isActive: json['is_active'] as bool? ?? false, // Provide default
      isApproved: json['is_approved'] as bool? ?? false, // Provide default
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'fcm_token': fcmToken,
      'vehicle_type': _vehicleTypeToString(vehicleType),
      'vehicle_details': vehicleDetails,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'is_available': isAvailable,
      'profile_picture': profilePictureUrl,
      'is_active': isActive,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName'.trim();
}
