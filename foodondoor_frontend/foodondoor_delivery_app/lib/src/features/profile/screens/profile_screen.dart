import 'package:flutter/material.dart';
import 'package:foodondoor_delivery_app/src/features/profile/models/delivery_agent_profile.dart';
import 'package:foodondoor_delivery_app/src/features/profile/providers/profile_provider.dart';
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
                if (profile.profilePictureUrl != null)
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(profile.profilePictureUrl!),
                      onBackgroundImageError: (exception, stackTrace) {
                        print('Error loading profile image: $exception');
                      },
                      child: profile.profilePictureUrl!.isEmpty 
                        ? const Icon(Icons.person, size: 50) 
                        : null,
                    ),
                  ),
                const SizedBox(height: 16),
                _buildProfileField(context, 'Name', profile.fullName),
                _buildProfileField(context, 'Phone Number', profile.phoneNumber),
                if (profile.email != null && profile.email!.isNotEmpty)
                  _buildProfileField(context, 'Email', profile.email!),
                _buildProfileField(context, 'Vehicle Type', profile.vehicleType.toString().split('.').last),
                if (profile.vehicleDetails != null && profile.vehicleDetails!.isNotEmpty)
                  _buildProfileField(context, 'Vehicle Details', profile.vehicleDetails!),
                _buildProfileField(context, 'Availability', profile.isAvailable ? 'Available' : 'Unavailable'),
                _buildProfileField(context, 'Approval Status', profile.isApproved ? 'Approved' : 'Pending Approval', 
                  valueColor: profile.isApproved ? Colors.green : Colors.orange),
                _buildProfileField(context, 'Account Status', profile.isActive ? 'Active' : 'Inactive'),
                _buildProfileField(context, 'Joined', profile.createdAt.toLocal().toString().split(' ')[0]),
                const SizedBox(height: 20),
                // Add links to Assigned Orders, Earnings, etc. later
                // Add toggle for availability later
                // SwitchListTile(
                //   title: const Text('Available for Deliveries'),
                //   value: profile.isAvailable,
                //   onChanged: (bool value) {
                //     // Call provider method to update availability
                //   },
                // ),
              ],
            );
          }

          return const Center(child: Text('No profile data available.'));
        },
      ),
    );
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
