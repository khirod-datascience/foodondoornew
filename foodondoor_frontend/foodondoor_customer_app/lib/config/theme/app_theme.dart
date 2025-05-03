import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Define App Colors (Inspired by Enatega/FoodOnDoor)
const Color _primaryColor = Color(0xFFF27121); // Orange from Enatega logo/buttons
const Color _secondaryColor = Color(0xFF4CAF50); // Keeping Green as secondary for now
const Color _backgroundColor = Color(0xFFF5F5F5); // Light grey background
const Color _textColor = Color(0xFF333333); // Dark grey text
const Color _whiteColor = Colors.white;
const Color _errorColor = Colors.redAccent;

// Create the ThemeData
ThemeData getAppTheme() {
  return ThemeData(
    useMaterial3: true,

    // Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFFD84315), // Deep Orange A700
      primary: Color(0xFFD84315), // Deep Orange A700
      secondary: Color(0xFFFF7043), // Deep Orange 400
      background: Color(0xFFF5F5F5),
      surface: Colors.white, // Card backgrounds, Dialogs etc.
      onPrimary: Colors.white, // Text on primary color
      onSecondary: Colors.white, // Text on secondary color
      onBackground: Color(0xFF333333), // Text on background
      onSurface: Color(0xFF333333), // Text on surface (cards)
      onError: Colors.white, // Text on error color
      error: Colors.redAccent,
      brightness: Brightness.light, // Light theme
    ),

    // Typography (using Google Fonts - Poppins is a good clean choice)
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: _textColor),
      displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: _textColor),
      displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: _textColor),
      headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: _textColor),
      headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: _textColor),
      titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _textColor),
      titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
      titleSmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _textColor),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal, color: _textColor),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal, color: _textColor),
      labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _whiteColor), // For button text
      bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.normal, color: _textColor.withOpacity(0.7)),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: _whiteColor, // Title and icons
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: _whiteColor),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: _whiteColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData( // Added style for outlined buttons like 'Register'
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: BorderSide(color: _primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      )
    ),

    // Input Decoration Theme (for TextFields)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _whiteColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300), // Light grey border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300), // Light grey border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _errorColor, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _errorColor, width: 2.0),
      ),
      hintStyle: GoogleFonts.poppins(color: _textColor.withOpacity(0.5)),
    ),

    // Card Theme
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Color(0xFFD84315).withOpacity(0.15),
      surfaceTintColor: Colors.transparent, // Prevent M3 tinting
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _secondaryColor,
      foregroundColor: _whiteColor,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _whiteColor,
      selectedItemColor: _primaryColor,
      unselectedItemColor: _textColor.withOpacity(0.6),
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}