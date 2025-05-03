import 'package:flutter/material.dart';
import 'package:foodondoor_vendor_app/src/features/profile/models/vendor_profile_model.dart';
import 'package:foodondoor_vendor_app/src/features/profile/providers/profile_provider.dart';
import 'package:foodondoor_vendor_app/src/utils/validators.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  static const routeName = '/edit-profile';
  final VendorProfile initialProfileData;

  const EditProfileScreen({super.key, required this.initialProfileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.initialProfileData.companyName);
    _emailController = TextEditingController(text: widget.initialProfileData.email);
    // Phone number is usually not editable directly by vendor in this flow
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final updateData = {
      'company_name': _businessNameController.text.trim(),
      'email': _emailController.text.trim(),
      // Only include fields that are allowed to be updated via this endpoint
      // Ensure keys match the backend serializer fields exactly.
    };

    final profileProvider = context.read<ProfileProvider>();
    
    // Call the actual provider method
    final bool success = await profileProvider.updateProfile(updateData);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        // Also trigger a refresh of the profile data in the provider after successful update
        // Do this *before* popping so the ProfileScreen shows fresh data.
        await profileProvider.fetchProfile(); 
        Navigator.pop(context); // Go back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(profileProvider.errorMessage ?? 'Update failed'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Business Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter your business name'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
