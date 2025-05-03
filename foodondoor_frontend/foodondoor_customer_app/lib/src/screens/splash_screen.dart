import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodondoor_customer_app/src/features/auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // No need to explicitly call auth check here.
    // AuthProvider's constructor handles the initial check.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<AuthProvider>(context, listen: false).checkAuthStatus(); 
    // });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
