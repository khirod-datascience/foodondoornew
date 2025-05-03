import 'package:flutter/material.dart';
import 'package:foodondoor_delivery_app/src/features/auth/providers/auth_provider.dart'; // Adjusted import
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food on Door - Delivery'), // Adjusted title
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome Delivery Agent!'), // Adjusted text
        // TODO: Build the actual Delivery Agent home screen UI here later
      ),
    );
  }
}
