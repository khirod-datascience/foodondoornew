import 'package:flutter/material.dart';
import 'package:foodondoor_vendor_app/src/features/profile/models/vendor_profile_model.dart';
import 'package:foodondoor_vendor_app/src/features/profile/services/profile_service.dart';
import 'package:foodondoor_vendor_app/src/features/auth/services/auth_service.dart';

enum ProfileStatus { 
  initial, 
  loading, 
  loaded, 
  error,
  updating, 
  updateError 
}

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService;
  final AuthService _authService;

  ProfileStatus _status = ProfileStatus.initial;
  VendorProfile? _profile;
  String? _errorMessage = '';

  ProfileStatus get status => _status;
  VendorProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;

  ProfileProvider(this._profileService, this._authService);

  Future<void> fetchProfile() async {
    if (_status == ProfileStatus.loading) return;
    _status = ProfileStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final fetchedProfile = await _profileService.getVendorProfile();
      if (fetchedProfile != null) {
        _profile = fetchedProfile;
        _status = ProfileStatus.loaded;
      } else {
        _errorMessage = 'Failed to load vendor profile data.';
        _status = ProfileStatus.error;
      }
    } on VendorNotApprovedException catch (e) {
      _status = ProfileStatus.error;
      _errorMessage = e.toString();
      print('[ProfileProvider] Vendor not approved: $e');
    } catch (e) {
      _status = ProfileStatus.error;
      _errorMessage = 'An unexpected error occurred: $e';
      print('[ProfileProvider] Error fetching profile: $e');
    } finally {
      if (_status != ProfileStatus.loaded) { 
          _status = ProfileStatus.error; 
      }
      notifyListeners();
    }
  }

  void clearProfile() {
    _profile = null;
    _status = ProfileStatus.initial;
    _errorMessage = '';
    notifyListeners();
  }

  void setStatus(ProfileStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    if (_status == ProfileStatus.updating) return false; 

    print('[ProfileProvider] Updating profile...');
    _status = ProfileStatus.updating;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _profileService.updateProfile(profileData);
      
      _profile = updatedProfile; 
      _status = ProfileStatus.loaded; 
      _errorMessage = null;
      print('[ProfileProvider] Profile updated successfully.');
      notifyListeners();
      return true;

    } catch (e) {
      _status = ProfileStatus.updateError;
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      print('[ProfileProvider] Error updating profile: $e');
      notifyListeners();
      return false;
    }
  }
}
