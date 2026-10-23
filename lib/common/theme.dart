import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: const Color(0xFF4F46E5),
  primaryColorDark: const Color(0xFF3730A3),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF4F46E5),
    secondary: Color(0xFF10B981),
    background: Color(0xFFF9FAFB),
  ),
  scaffoldBackgroundColor: const Color(0xFFF9FAFB),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    iconTheme: const IconThemeData(color: Colors.black87),
  ),
  textTheme: TextTheme(
    headlineLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    titleSmall: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      color: Colors.black87,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      color: Colors.black87,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 12,
      color: Colors.grey[600],
    ),
  ),
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    buttonColor: const Color(0xFF4F46E5),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4F46E5),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      elevation: 5,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF4F46E5)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    hintStyle: GoogleFonts.poppins(
      color: const Color(0xFF9CA3AF),
    ),
    labelStyle: GoogleFonts.poppins(
      color: const Color(0xFF6B7280),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: EdgeInsets.zero,
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey[300],
    thickness: 1,
    space: 1,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: const Color(0xFF4F46E5),
    unselectedItemColor: const Color(0xFF6B7280),
    selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
    unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
    type: BottomNavigationBarType.fixed,
    elevation: 10,
  ),
);