import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:foodondoor_customer_app/src/features/auth/providers/auth_provider.dart';
import 'package:foodondoor_customer_app/src/features/auth/screens/otp_verification_screen.dart'; 
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = _phoneController.text.trim();
    final fullPhoneNumber = '+91$phone'; 

    try {
      final success = await authProvider.sendOtp(phone); 

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(
          OtpVerificationScreen.routeName,
          arguments: fullPhoneNumber, 
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty)
                ? authProvider.errorMessage! 
                : 'Login failed. Please try again.'
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0), 
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [
                  Icon(
                    Icons.food_bank_rounded,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'FoodOnDoor',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your phone number to login or sign up',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40), 
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '98765 43210',
                      prefixIcon: Icon(Icons.phone_android_rounded, color: colorScheme.primary),
                      prefixText: '+91 ',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: textTheme.bodyLarge, 
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.trim().length != 10) {
                        return 'Enter a valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32), 
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit, 
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), 
                      ))
                    ),
                    child: isLoading 
                        ? SizedBox( // Constrain the size of the indicator
                            height: 24, 
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3, 
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                            ),
                          )
                        : Text('Get OTP', style: textTheme.labelLarge?.copyWith(fontSize: 16)), 
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
