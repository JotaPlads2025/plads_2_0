import 'package:flutter/material.dart';

class AppColors {
  // Soft Neon Palette
  // Original Green: 0xFF39FF14, Purple: 0xFFD000FF
  // New Soft Versions (Slightly less brightness/saturation or shifted)
  
  static const Color neonGreen = Color(0xFF4ADE80); // Tailwind Green-400 equivalent, softer
  static const Color neonPurple = Color(0xFFC084FC); // Tailwind Purple-400 equivalent, softer
  static const Color neonBlue = Color(0xFF60A5FA); // Tailwind Blue-400 equivalent, softer
  
  static const Color neonGreenBright = Color(0xFF39FF14); // Keep for tiny accents if needed
  static const Color neonPurpleBright = Color(0xFFD000FF);

  static const Color backgroundBlack = Color(0xFF121212); // Soft black, Material surface
  static const Color surfaceGrey = Color(0xFF1E1E1E);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundBlack,
      primaryColor: AppColors.neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonGreen,
        secondary: AppColors.neonPurple,
        surface: AppColors.surfaceGrey,
        background: AppColors.backgroundBlack,
      ),
      fontFamily: 'Inter', // Assuming standard font or default
      useMaterial3: true,
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceGrey,
        labelStyle: const TextStyle(color: AppColors.textGrey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Compact padding
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: AppColors.neonGreen.withOpacity(0.4),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textGrey,
        ),
      ),
    );
  }
}
