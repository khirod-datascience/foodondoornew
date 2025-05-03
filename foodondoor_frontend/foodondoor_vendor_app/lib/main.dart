import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foodondoor_vendor_app/src/theme/app_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import 'package:dio/dio.dart'; 

import 'package:foodondoor_vendor_app/src/features/auth/providers/auth_provider.dart';
import 'package:foodondoor_vendor_app/src/features/auth/services/auth_service.dart'; 
import 'package:foodondoor_vendor_app/src/features/profile/providers/profile_provider.dart';
import 'package:foodondoor_vendor_app/src/features/profile/services/profile_service.dart'; 
import 'package:foodondoor_vendor_app/src/features/profile/models/vendor_profile_model.dart'; 
import 'package:foodondoor_vendor_app/src/features/menu/providers/menu_provider.dart'; 
import 'package:foodondoor_vendor_app/src/features/menu/services/menu_service.dart'; 
import 'package:foodondoor_vendor_app/src/features/menu/providers/category_provider.dart'; 
import 'package:foodondoor_vendor_app/src/features/menu/services/category_service.dart'; 
import 'package:foodondoor_vendor_app/src/features/restaurant/providers/restaurant_provider.dart'; 
import 'package:foodondoor_vendor_app/src/features/restaurant/services/restaurant_service.dart'; 
import 'package:foodondoor_vendor_app/src/features/restaurant/screens/restaurant_profile_screen.dart'; 
import 'package:foodondoor_vendor_app/src/features/restaurant/screens/edit_restaurant_screen.dart'; 
import 'package:foodondoor_vendor_app/src/features/restaurant/models/restaurant_model.dart'; 
import 'package:foodondoor_vendor_app/src/features/order_service.dart'; 
import 'package:foodondoor_vendor_app/src/features/order_provider.dart'; 
import 'package:foodondoor_vendor_app/src/features/order_list_screen.dart';
import 'package:foodondoor_vendor_app/src/features/restaurant/providers/restaurant_provider.dart';
import 'package:foodondoor_vendor_app/src/features/restaurant/screens/restaurant_screen.dart';

import 'package:foodondoor_vendor_app/src/features/auth/screens/login_screen.dart'; 
import 'package:foodondoor_vendor_app/src/features/auth/screens/otp_verification_screen.dart'; 
import 'package:foodondoor_vendor_app/src/features/home/screens/home_screen.dart'; 
import 'package:foodondoor_vendor_app/src/features/profile/screens/profile_screen.dart';
import 'package:foodondoor_vendor_app/src/features/auth/screens/registration_screen.dart'; 
import 'package:foodondoor_vendor_app/src/features/profile/screens/edit_profile_screen.dart';

import 'package:foodondoor_vendor_app/src/constants/api_constants.dart'; 
import 'package:foodondoor_vendor_app/src/utils/secure_storage_service.dart'; 

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Provide Dio instance with BaseOptions
        Provider<Dio>(
          create: (_) => Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)),
        ),
 
        Provider<FlutterSecureStorage>(create: (_) => const FlutterSecureStorage()),
 
        // AuthService depends on Dio and Storage
        Provider<AuthService>(
          create: (context) => AuthService(context.read<Dio>(), context.read<FlutterSecureStorage>()),
        ),
        // AuthProvider depends on AuthService
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
        ),
 
        // ProfileService depends on Dio and AuthService
        ProxyProvider2<Dio, AuthService, ProfileService>(
          update: (_, dio, authService, __) => ProfileService(dio, authService),
        ),
        // ProfileProvider depends on ProfileService and AuthService
        ChangeNotifierProxyProvider2<ProfileService, AuthService, ProfileProvider>(
          create: (context) => ProfileProvider(context.read<ProfileService>(), context.read<AuthService>()),
          update: (_, profileService, authService, previousNotifier) => 
              previousNotifier ?? ProfileProvider(profileService, authService),
        ),
 
        // RestaurantService depends on Dio and AuthService
        ProxyProvider2<Dio, AuthService, RestaurantService>(
          update: (_, dio, authService, __) => RestaurantService(dio, authService),
        ),
        // RestaurantProvider depends on RestaurantService
        ChangeNotifierProxyProvider<RestaurantService, RestaurantProvider>(
          create: (context) => RestaurantProvider(context.read<RestaurantService>()),
          update: (_, restaurantService, previousProvider) => previousProvider ?? RestaurantProvider(restaurantService),
        ),
 
        // CategoryService depends on Dio (adjust if it needs AuthService too)
        ProxyProvider<Dio, CategoryService>(
          update: (_, dio, __) => CategoryService(dio),
        ),
        // CategoryNotifier depends on CategoryService
        ChangeNotifierProxyProvider<CategoryService, CategoryNotifier>(
          create: (context) => CategoryNotifier(context.read<CategoryService>()),
          update: (_, categoryService, previousNotifier) => previousNotifier ?? CategoryNotifier(categoryService),
        ),

        // MenuService depends on Dio, AuthService, and Storage
        ProxyProvider3<Dio, AuthService, FlutterSecureStorage, MenuService>(
          update: (_, Dio dio, AuthService authService, FlutterSecureStorage storage, __) => MenuService(dio, authService, storage), // Explicit types
        ),
        // MenuNotifier depends on MenuService
        ChangeNotifierProxyProvider<MenuService, MenuNotifier>(
          create: (context) => MenuNotifier(context.read<MenuService>()),
          update: (_, menuService, previousNotifier) => previousNotifier ?? MenuNotifier(menuService),
        ),

        // OrderService depends on Dio and AuthService
        ProxyProvider2<Dio, AuthService, OrderService>(
          update: (_, dio, authService, __) => OrderService(dio, authService),
        ),
        // OrderProvider depends on OrderService
        ChangeNotifierProxyProvider<OrderService, OrderProvider>(
          create: (context) => OrderProvider(context.read<OrderService>()),
          update: (_, orderService, previousNotifier) => previousNotifier ?? OrderProvider(orderService),
        ),

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
      title: 'FoodOndoor Vendor',
       theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          print("[Main Consumer] Auth Status: ${authProvider.status}"); 
          switch (authProvider.status) {
            case AuthStatus.initial:
            case AuthStatus.authenticating:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case AuthStatus.awaitingOtp: 
              final phoneNumber = authProvider.phoneNumber;
              if (phoneNumber != null) {
                print("[Main Consumer] Navigating to OtpVerificationScreen for $phoneNumber");
                return OtpVerificationScreen(phoneNumber: phoneNumber);
              } else {
                print("[Main Consumer] Error: awaitingOtp status but no phoneNumber found. Returning to Login.");
                return const LoginScreen(); 
              }
            case AuthStatus.needsProfileSetup: 
              print("[Main Consumer] Navigating to ProfileScreen (for registration)");
              return const ProfileScreen(); 
            case AuthStatus.authenticated:
              print("[Main Consumer] Navigating to HomeScreen");
              return const HomeScreen(); 
            case AuthStatus.unauthenticated:
            case AuthStatus.registrationFailed: 
            case AuthStatus.otpVerificationFailed:
            default:
              print("[Main Consumer] Navigating to LoginScreen (default/unauthenticated/error)");
              return const LoginScreen(); 
          }
        },
      ),
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        RestaurantProfileScreen.routeName: (context) => const RestaurantProfileScreen(), 
        OrderListScreen.routeName: (context) => const OrderListScreen(),
        RestaurantScreen.routeName: (context) => const RestaurantScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == EditRestaurantScreen.routeName) {
          final args = settings.arguments as Restaurant?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) {
                return EditRestaurantScreen(initialRestaurantData: args);
              },
            );
          } else {
            print("Error: EditRestaurantScreen requires Restaurant argument");
             return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Error: Missing restaurant data for edit screen'))));
          }
        }
        if (settings.name == OtpVerificationScreen.routeName) {
          final args = settings.arguments as String?;
          if (args != null) {
             return MaterialPageRoute(
               builder: (context) {
                 return OtpVerificationScreen(phoneNumber: args);
               },
             );
          } else {
             print("Error: OtpVerificationScreen requires phone number argument");
              return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Error: Missing phone number for OTP screen'))));
          }
        }
        if (settings.name == EditProfileScreen.routeName) {
          final profile = settings.arguments as VendorProfile?;
          if (profile != null) {
             return MaterialPageRoute(
               builder: (context) {
                 return EditProfileScreen(initialProfileData: profile);
               },
             );
          } else {
             print("Error: EditProfileScreen requires VendorProfile argument");
              return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Error: Missing profile data for edit screen'))));
          }
        }

        assert(false, 'Need to implement ${settings.name}');
        return null; 
      },
    );
  }
}
