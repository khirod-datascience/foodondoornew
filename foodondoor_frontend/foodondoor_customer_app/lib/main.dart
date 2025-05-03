import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foodondoor_customer_app/src/features/auth/providers/auth_provider.dart';
import 'package:foodondoor_customer_app/src/features/auth/screens/login_screen.dart';
import 'package:foodondoor_customer_app/src/features/auth/screens/otp_verification_screen.dart';
import 'package:foodondoor_customer_app/src/features/auth/screens/registration_screen.dart';
import 'package:foodondoor_customer_app/src/features/auth/services/auth_service.dart';
import 'package:foodondoor_customer_app/src/features/home/screens/home_screen.dart';
import 'package:foodondoor_customer_app/src/features/profile/providers/profile_provider.dart';
import 'package:foodondoor_customer_app/src/features/profile/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'src/screens/splash_screen.dart';
import 'config/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final authService = AuthService(); 
            const secureStorage = FlutterSecureStorage(); 
            return AuthProvider(
              authService: authService, 
              secureStorage: secureStorage,
            );
          },
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodOnDoor Customer',
      theme: getAppTheme(),
      darkTheme: getAppTheme(),
      themeMode: ThemeMode.light,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          switch (auth.status) {
            case AuthStatus.initial: 
              return const SplashScreen(); 
            case AuthStatus.authenticated:
              return const HomeScreen();
            // Keep showing LoginScreen during loading or when signup is required
            // The navigation to registration will happen from OtpVerificationScreen
            case AuthStatus.loading: 
            case AuthStatus.signupRequired: 
            case AuthStatus.unauthenticated:
            case AuthStatus.error: 
            default:
              return const LoginScreen();
          }
        },
      ),
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        OtpVerificationScreen.routeName: (context) => const OtpVerificationScreen(),
        RegistrationScreen.routeName: (context) {
          final signupToken = ModalRoute.of(context)?.settings.arguments as String?;
          if (signupToken == null) {
            print("[main.dart] Error: Registration route called without signupToken argument.");
            return const LoginScreen(); 
          }
          return RegistrationScreen(signupToken: signupToken);
        },
        HomeScreen.routeName: (context) => const HomeScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        '/splash': (context) => const SplashScreen(), 
      },
    );
  }
}
