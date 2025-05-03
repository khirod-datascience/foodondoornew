import 'package:flutter/material.dart';
import 'package:foodondoor_vendor_app/src/features/restaurant/providers/restaurant_provider.dart';
import 'package:foodondoor_vendor_app/src/features/restaurant/screens/edit_restaurant_screen.dart';
import 'package:foodondoor_vendor_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:provider/provider.dart';

class RestaurantScreen extends StatefulWidget {
  static const routeName = '/restaurant-details';

  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch details when the screen is initialized
    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use read here as we only need to trigger the fetch once
      context.read<RestaurantProvider>().fetchRestaurantDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Details'),
        actions: [
          Consumer<RestaurantProvider>(
            builder: (context, provider, child) {
              // Only show edit button if data is loaded and not null
              if (provider.status == RestaurantStatus.loaded && provider.restaurant != null) {
                return IconButton(
                  icon: Icon(Icons.edit),
                  tooltip: 'Edit Restaurant Details',
                  onPressed: () {
                    // Navigate to Edit Screen, passing the current restaurant data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditRestaurantScreen(
                          initialRestaurantData: provider.restaurant!,
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink(); // Return empty widget otherwise
            },
          )
        ],
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          switch (provider.status) {
            case RestaurantStatus.loading:
            case RestaurantStatus.initial:
              return const Center(child: CircularProgressIndicator());
            case RestaurantStatus.error:
            case RestaurantStatus.updateError: // Show error for update failures too
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    provider.errorMessage ?? 'Failed to load restaurant details.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            case RestaurantStatus.updating: // Show loading while updating
              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent)));
            case RestaurantStatus.loaded:
              final restaurant = provider.restaurant;
              if (restaurant == null) {
                // This might happen if the vendor doesn't have a restaurant yet (e.g., 404 from API)
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Restaurant profile not found. You might need to create one first.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // --- Display Restaurant Details ---
              return RefreshIndicator(
                onRefresh: () => provider.fetchRestaurantDetails(),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildDetailTile(Icons.store, 'Name', restaurant.name),
                    if (restaurant.description != null && restaurant.description!.isNotEmpty)
                      _buildDetailTile(Icons.description, 'Description', restaurant.description!),
                    _buildAddressTile(restaurant),
                    if (restaurant.phoneNumber != null && restaurant.phoneNumber!.isNotEmpty)
                      _buildDetailTile(Icons.phone, 'Phone', restaurant.phoneNumber!),
                    if (restaurant.logoUrl != null && restaurant.logoUrl!.isNotEmpty)
                      _buildImageTile('Logo', restaurant.logoUrl!),
                    if (restaurant.coverPhotoUrl != null && restaurant.coverPhotoUrl!.isNotEmpty)
                      _buildImageTile('Cover Photo', restaurant.coverPhotoUrl!),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      dense: true,
    );
  }

  // Helper widget to display the combined address
  Widget _buildAddressTile(Restaurant restaurant) {
    final addressParts = [
      restaurant.address,
      restaurant.city,
      restaurant.state,
      restaurant.postalCode,
    ].where((part) => part != null && part.isNotEmpty).toList();

    if (addressParts.isEmpty) {
      return const SizedBox.shrink(); // Don't show tile if no address parts exist
    }

    return ListTile(
      leading: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
      title: const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        addressParts.join(', '),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      dense: true,
    );
  }

  // Helper widget to display images (basic implementation)
  Widget _buildImageTile(String title, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Center(
            child: Image.network(
              imageUrl,
              height: 150, // Adjust height as needed
              fit: BoxFit.cover,
              // Add error and loading builders for better UX
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
              },
            ),
          ),
        ],
      ),
    );
  }
}
