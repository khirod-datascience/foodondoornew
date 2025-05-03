import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for input formatters
import 'package:foodondoor_customer_app/src/features/auth/providers/auth_provider.dart';
import 'package:foodondoor_customer_app/src/features/home/screens/home_screen.dart'; // We'll create this placeholder next
import 'package:foodondoor_customer_app/src/features/auth/screens/registration_screen.dart'; // Import the new registration screen
import 'package:provider/provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  static const routeName = '/otp-verification';

  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submitOtp(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final otpCode = _otpController.text;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Call verifyOtp - it now returns false for signupRequired
      // We will check the provider status after the call
      await authProvider.verifyOtp(otpCode); 

      // Check the status AFTER the await completes
      // Use 'mounted' check for safety in async gaps
      if (!mounted) return; 

      switch (authProvider.status) {
        case AuthStatus.authenticated:
          print('[OtpVerificationScreen] Authentication successful. Navigating to Home.');
          Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
          break;
        case AuthStatus.signupRequired:
          print('[OtpVerificationScreen] Signup required. Navigating to Registration.');
          final signupToken = authProvider.signupToken;
          if (signupToken != null) {
            // Navigate to RegistrationScreen
            Navigator.of(context).pushReplacementNamed(
              RegistrationScreen.routeName,
              arguments: signupToken,
            );
          } else {
            // Handle error: signup required but no token available
             print('[OtpVerificationScreen] Error: Signup required but no signup token found.');
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Signup cannot proceed: Missing token.')), 
             );
          }
          break;
        case AuthStatus.error:
          print('[OtpVerificationScreen] Error: ${authProvider.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.errorMessage ?? 'OTP Verification Failed')),
          );
          break;
        default:
          // Handle other statuses if necessary (e.g., loading, initial)
          print('[OtpVerificationScreen] Unexpected status after verifyOtp: ${authProvider.status}');
          break;
      }
    }
  }

  Future<void> _resendOtp(String? phoneNumber) async {
    if (phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: const Text('Phone number not found.'), backgroundColor: Theme.of(context).colorScheme.error),
       );
      return;
    }
    // TODO: Add a cooldown timer before allowing resend
    print('Resending OTP to $phoneNumber');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      // Assuming sendOtp takes the 10-digit number (extract from fullPhoneNumber if needed)
      final phoneWithoutCode = phoneNumber.startsWith('+91') ? phoneNumber.substring(3) : phoneNumber;
      await authProvider.sendOtp(phoneWithoutCode); 
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('New OTP sent successfully!'), backgroundColor: Colors.green),
           );
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resend OTP: ${e.toString()}'),
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

    // Retrieve the phone number passed from LoginScreen
    final String? phoneNumber = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'), // Updated title
        backgroundColor: Colors.transparent, // Make appbar transparent
        elevation: 0,
        foregroundColor: colorScheme.primary, // Use primary color for back button
      ),
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
                  Text(
                    'Enter OTP',
                    style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A 6-digit code has been sent to\n${phoneNumber ?? 'your phone'}', // Display phone number
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'OTP Code',
                      hintText: '------', // Hint for 6 digits
                      prefixIcon: Icon(Icons.password_rounded, color: colorScheme.primary),
                      counterText: "", // Hide the default counter
                      // Use theme defaults, can customize border radius etc. if needed
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center, // Center the OTP input
                    style: textTheme.headlineSmall?.copyWith(letterSpacing: 8.0), // Add spacing for OTP look
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6), // Limit to 6 digits
                    ],
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the OTP';
                      }
                      if (value.trim().length != 6) {
                        return 'OTP must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () {
                            // Access provider without listening for button state
                            final authProvider = context.read<AuthProvider>();
                            if (authProvider.status != AuthStatus.loading) {
                               _submitOtp(context);
                            }
                          },
                          style: theme.elevatedButtonTheme.style?.copyWith(
                             padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                             shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                             ))
                          ),
                          child: Consumer<AuthProvider>(
                            builder: (context, auth, child) {
                              // Show loading indicator inside button if loading
                              if (auth.status == AuthStatus.loading) {
                                return const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                );
                              } else {
                                 return const Text('Verify OTP');
                              }
                            },
                          ),
                        ),
                  const SizedBox(height: 20),
                  // Resend OTP Button
                  TextButton(
                      onPressed: isLoading ? null : () => _resendOtp(phoneNumber), // Pass phone number
                      child: Text(
                        'Didn\'t receive code? Resend OTP',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)
                      ),
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
