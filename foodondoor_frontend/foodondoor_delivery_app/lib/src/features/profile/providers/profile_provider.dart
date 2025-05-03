import 'package:flutter/material.dart';
import 'package:foodondoor_delivery_app/src/features/profile/models/delivery_agent_profile.dart';
import 'package:foodondoor_delivery_app/src/features/profile/services/profile_service.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  ProfileStatus _status = ProfileStatus.initial;
  DeliveryAgentProfile? _profile;
  String _errorMessage = '';

  ProfileStatus get status => _status;
  DeliveryAgentProfile? get profile => _profile;
  String get errorMessage => _errorMessage;

  Future<void> fetchProfile() async {
    _status = ProfileStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final fetchedProfile = await _profileService.getDeliveryAgentProfile();
      if (fetchedProfile != null) {
        _profile = fetchedProfile;
        _status = ProfileStatus.loaded;
      } else {
        _errorMessage = 'Failed to load delivery agent profile data.';
        _status = ProfileStatus.error;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    _status = ProfileStatus.initial;
    _errorMessage = '';
    notifyListeners();
  }

  // Add methods for updating profile/location later
}
