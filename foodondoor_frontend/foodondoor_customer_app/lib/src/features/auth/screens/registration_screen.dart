import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../home/screens/home_screen.dart'; // For potential navigation after success

class RegistrationScreen extends StatefulWidget {
  static const routeName = '/registration';

  final String signupToken; // Received from OTP verification

  const RegistrationScreen({super.key, required this.signupToken});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  // Add more controllers as needed (e.g., password, address)

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Validation failed
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firstName = _nameController.text.trim();
    // Assuming only first name and email for now based on controllers
    final lastName = ''; // Or add a controller for last name if needed
    final email = _emailController.text.trim();

    print('[RegistrationScreen] Attempting registration...');
    print('[RegistrationScreen] First Name: $firstName, Email: $email');
    print('[RegistrationScreen] Using Signup Token: ${widget.signupToken}');

    // --- Call AuthProvider to register --- 
    bool success = await authProvider.registerUser(
      firstName: firstName,
      lastName: lastName, // Pass last name if collected
      email: email,
      signupToken: widget.signupToken,
    );
    
    // Check mounted state AFTER the async call
    if (!mounted) return; 

    setState(() {
      _isLoading = false;
    });

    if (success) {
      print('[RegistrationScreen] Registration successful. Navigating home.');
      // Navigate to Home on successful registration
      Navigator.of(context).pushNamedAndRemoveUntil(HomeScreen.routeName, (route) => false);
    } else {
      print('[RegistrationScreen] Registration failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Registration'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us a bit about yourself', 
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              // Add more fields here (e.g., password, address) if needed
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                style: theme.elevatedButtonTheme.style?.copyWith(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                ),
                child: _isLoading 
                  ? const SizedBox(
                      width: 24, 
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    ) 
                  : Text('Complete Registration', style: textTheme.labelLarge?.copyWith(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
