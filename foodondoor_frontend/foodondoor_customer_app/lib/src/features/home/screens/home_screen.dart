import 'package:flutter/material.dart';
import 'package:foodondoor_customer_app/src/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food on Door - Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              // Navigation logic to go back to login screen will be handled
              // by the main app widget observing the auth state.
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome! You are logged in.'),
        // TODO: Build the actual home screen UI here later
      ),
    );
  }
}
