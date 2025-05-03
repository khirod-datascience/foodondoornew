import 'package:flutter/material.dart';
import 'package:foodondoor_vendor_app/src/features/profile/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:foodondoor_vendor_app/src/features/auth/providers/auth_provider.dart';
import 'package:foodondoor_vendor_app/src/utils/validators.dart';
import 'package:foodondoor_vendor_app/src/features/profile/models/vendor_profile_model.dart'; // Import the model
import 'package:foodondoor_vendor_app/src/features/restaurant/screens/restaurant_screen.dart'; // Added import
import 'package:foodondoor_vendor_app/src/features/profile/screens/edit_profile_screen.dart'; // Added import

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Form state for profile creation
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _emailController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _emailController = TextEditingController();

    // Fetch profile only if already authenticated (not during initial setup)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use read here as we only need the status once initially
      final authStatus = Provider.of<AuthProvider>(context, listen: false).status;
      if (authStatus == AuthStatus.authenticated) {
         Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
      }
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Method to handle the profile submission during registration flow
  Future<void> _submitRegistrationForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't submit if validation fails
    }
    _formKey.currentState!.save(); // Optional: good practice if using onSaved

    setState(() {
      _isSubmitting = true;
    });

    // Prepare data according to VendorRegistrationSerializer
    final profileData = {
      'company_name': _businessNameController.text.trim(),
      'email': _emailController.text.trim(),
      // phone_number is handled by the backend using the signup token
    };

    // Use read as we don't need to listen here, just call the method
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.completeRegistration(profileData);

    // Check if the widget is still in the tree after the async operation
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (!success && authProvider.errorMessage != null) {
        // Show error message if submission failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } 
      // No explicit navigation needed here - the main Consumer<AuthProvider>
      // will handle navigating to HomeScreen if status changes to authenticated.
    }
  }

  // Method to handle navigation to the edit profile screen
  void _navigateToEditProfile(BuildContext context, VendorProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialProfileData: profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch AuthProvider status to react to changes (e.g., after successful submission)
    final authStatus = context.watch<AuthProvider>().status;
    // Also watch for potential errors during submission
    final authErrorMessage = context.select<AuthProvider, String?>((p) => p.errorMessage);


    return Scaffold(
      appBar: AppBar(
        title: Text(authStatus == AuthStatus.needsProfileSetup
            ? 'Setup Your Profile'
            : 'Vendor Profile'),
        // Hide back button during profile setup?
        automaticallyImplyLeading: authStatus != AuthStatus.needsProfileSetup,
        actions: [
          // Only show edit button if authenticated and profile is loaded
          if (authStatus == AuthStatus.authenticated &&
              context.watch<ProfileProvider>().status == ProfileStatus.loaded &&
              context.watch<ProfileProvider>().profile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
              onPressed: () {
                final profile = context.read<ProfileProvider>().profile!;
                _navigateToEditProfile(context, profile);
              },
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // Show loading indicator centrally if AuthProvider is loading (e.g., during submission)
          // Note: AuthProvider's loading state might conflict with ProfileProvider's loading state.
          // Consider a more specific loading state in AuthProvider if needed.
          // if (authStatus == AuthStatus.loading) {
          if (authStatus == AuthStatus.authenticating) {

              return const Center(child: CircularProgressIndicator());
          }

          if (authStatus == AuthStatus.needsProfileSetup) {
            // --- Profile Setup Form ---
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome! Please complete your business details.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
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
                      validator: Validators.validateEmail, // Use validator function
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      // Use the new submission handler
                      onPressed: _isSubmitting ? null : _submitRegistrationForm, 
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Complete Registration'),
                    ),
                    // Display submission error message if any
                    // Note: We watch authErrorMessage at the top of build
                    if (authErrorMessage != null && authErrorMessage.isNotEmpty && !_isSubmitting)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          authErrorMessage,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            );
          } else if (authStatus == AuthStatus.authenticated) {
            // Existing logic for when the user is authenticated and profile might be loading/loaded/error
            return Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                if (provider.status == ProfileStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.status == ProfileStatus.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error loading profile: ${provider.errorMessage}'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          // Retry fetch only makes sense if authenticated
                          onPressed: () => provider.fetchProfile(), 
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.status == ProfileStatus.loaded && provider.profile != null) {
                  final profile = provider.profile!;
                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.business, color: Colors.blueAccent),
                        title: const Text('Business Name'),
                        subtitle: Text(profile.companyName, style: Theme.of(context).textTheme.titleLarge),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.blueAccent),
                        title: const Text('Registered Email'),
                        subtitle: Text(profile.email, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.phone, color: Colors.greenAccent),
                        title: const Text('Registered Phone'),
                        subtitle: Text(profile.user.phoneNumber, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const Divider(height: 32),
                      ListTile(
                        leading: const Icon(Icons.storefront, color: Colors.purpleAccent),
                        title: const Text('Manage Restaurant'),
                        subtitle: const Text('View or update your restaurant details'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, RestaurantScreen.routeName);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.edit_note, color: Colors.tealAccent),
                        title: const Text('Edit Business Details'),
                        subtitle: const Text('Update company name or email'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                           final profile = context.read<ProfileProvider>().profile!;
                           _navigateToEditProfile(context, profile);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                        title: const Text('Logout'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          _confirmLogout(context); // Extracted to separate method
                        },
                      ),
                    ],
                  );
                }

                // Fallback for authenticated state if profile is somehow null after loading
                // Check for not approved error and show dialog
                final errorMessage = context.select<ProfileProvider, String?>((p) => p.errorMessage);
                if (errorMessage != null && errorMessage.toLowerCase().contains('not approved')) {
                  // Show a blocking dialog
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Account Not Approved'),
                        content: Text(errorMessage),
                        actions: [
                          TextButton(
                            onPressed: () {
                              // TODO: Replace with actual support action (e.g., open email or support chat)
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Contact Support'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  });
                  return const Center(child: Text('Your account is not approved yet. Please contact support.'));
                }
                return const Center(child: Text('Profile data not available.')); 
              },
            );
          } else {
             // Handle other states like unauthenticated or loading (though main.dart should prevent this screen)
             // Consider showing specific message if authStatus is error
             return const Center(child: Text('Invalid State or Error'));
          }
        },
      ),
    );
  }

  // Confirmation Dialog for Logout
  Future<void> _confirmLogout(BuildContext context) async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
            ),
          ],
        );
      },
    );

    // If confirmed, perform logout
    if (confirmLogout == true && context.mounted) {
      // Use context.read for actions/calls in callbacks
      await context.read<AuthProvider>().logout();
      // Navigation is handled by the main wrapper based on auth state change
    }
  }

  Widget _buildProfileField(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: valueColor),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
