import 'package:flutter/material.dart';
import 'package:foodondoor_delivery_app/src/features/auth/providers/auth_provider.dart';
import 'package:foodondoor_delivery_app/src/features/auth/screens/login_screen.dart';
import 'package:foodondoor_delivery_app/src/features/auth/screens/otp_verification_screen.dart';
import 'package:foodondoor_delivery_app/src/features/home/screens/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Add other global providers for the Delivery app here
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
      title: 'FOODONDOOR Delivery',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrangeAccent,
          secondary: Colors.deepOrange,
        ),
        fontFamily: GoogleFonts.poppins().fontFamily,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.deepOrangeAccent, width: 2.0),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.deepOrangeAccent.withOpacity(0.2),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrangeAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
            shadowColor: Colors.deepOrangeAccent.withOpacity(0.15),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        )
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          switch (auth.status) {
            case AuthStatus.loading:
            case AuthStatus.initial:
              // Replace with your actual Splash Screen if available
              return const Scaffold(body: Center(child: CircularProgressIndicator())); 
            case AuthStatus.authenticated:
              return const HomeScreen();
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
        HomeScreen.routeName: (context) => const HomeScreen(),
      },
    );
  }
}
