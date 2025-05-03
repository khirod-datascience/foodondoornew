import 'package:flutter/material.dart';
import 'package:foodondoor_customer_app/src/features/profile/models/customer_profile.dart';
import 'package:foodondoor_customer_app/src/features/profile/services/profile_service.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  ProfileStatus _status = ProfileStatus.initial;
  CustomerProfile? _profile;
  String _errorMessage = '';

  ProfileStatus get status => _status;
  CustomerProfile? get profile => _profile;
  String get errorMessage => _errorMessage;

  // Optionally call fetchProfile immediately when the provider is created
  // ProfileProvider() {
  //   fetchProfile();
  // }

  Future<void> fetchProfile() async {
    _status = ProfileStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final fetchedProfile = await _profileService.getCustomerProfile();
      if (fetchedProfile != null) {
        _profile = fetchedProfile;
        _status = ProfileStatus.loaded;
      } else {
        _errorMessage = 'Failed to load profile data.';
        _status = ProfileStatus.error;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  // Method to clear profile data on logout
  void clearProfile() {
    _profile = null;
    _status = ProfileStatus.initial;
    _errorMessage = '';
    notifyListeners();
  }

  // Add methods for updating profile later
}
