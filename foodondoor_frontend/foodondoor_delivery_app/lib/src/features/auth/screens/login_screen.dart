import 'package:flutter/material.dart';
import 'package:foodondoor_delivery_app/src/features/auth/providers/auth_provider.dart'; // Adjusted import
import 'package:foodondoor_delivery_app/src/features/auth/screens/otp_verification_screen.dart'; // Adjusted import
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phoneNumber = '+91${_phoneController.text.trim()}'; // Assuming IN country code

    final success = await authProvider.sendOtp(phoneNumber);

    if (success && mounted) {
      Navigator.of(context).pushNamed(OtpVerificationScreen.routeName);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage.isNotEmpty
                ? authProvider.errorMessage
                : 'Failed to send OTP. Please check the number and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Agent Login/Register'), // Adjusted title
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Enter your mobile number to login or register',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: 'Enter your 10-digit mobile number',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your mobile number';
                    }
                    if (value.trim().length != 10 || int.tryParse(value.trim()) == null) {
                      return 'Please enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Get OTP'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
