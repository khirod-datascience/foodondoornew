import 'package:flutter/material.dart';
import 'package:foodondoor_customer_app/src/features/profile/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  void initState() {
    super.initState();
    // Fetch profile when the screen is first loaded
    // Use addPostFrameCallback to ensure the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        // Add edit button later
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.edit),
        //     onPressed: () {
        //       // Navigate to edit profile screen
        //     },
        //   ),
        // ],
      ),
      body: Consumer<ProfileProvider>(
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
                _buildProfileField(context, 'Name', profile.fullName),
                _buildProfileField(context, 'Phone Number', profile.phoneNumber),
                if (profile.email != null && profile.email!.isNotEmpty)
                  _buildProfileField(context, 'Email', profile.email!),
                _buildProfileField(context, 'Joined', profile.createdAt.toLocal().toString().split(' ')[0]), // Show date only
                const SizedBox(height: 20),
                // Add other sections like Addresses, Order History links later
              ],
            );
          }

          // Initial or unexpected state
          return const Center(child: Text('No profile data available.'));
        },
      ),
    );
  }

  Widget _buildProfileField(BuildContext context, String label, String value) {
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
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Divider(),
        ],
      ),
    );
  }
}
