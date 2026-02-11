import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Neon Palette
  static const Color primaryColor = Color(0xFF00F0FF); // Neon Cyan
  static const Color secondaryColor = Color(0xFF7000FF); // Neon Purple
  static const Color accentColor = Color(0xFFFF0099); // Neon Pink
  static const Color successColor = Color(0xFF39FF14); // Neon Green
  static const Color warningColor = Color(0xFFFFD300); // Neon Yellow
  static const Color errorColor = Color(0xFFFF3131); // Neon Red

  // Dark Background Palette
  static const Color backgroundStart = Color(0xFF0F0C29); // Deep Blue/Black
  static const Color backgroundEnd = Color(0xFF24243E); // Lighter Deep Blue

  static const Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E), // Dark Navy
      Color(0xFF16213E), // Slightly lighter
      Color(0xFF0F3460), // Deep blue accent
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF), // White with 10% opacity
      Color(0x0DFFFFFF), // White with 5% opacity
    ],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: Colors.transparent, // Important for glassmorphism
        error: errorColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      scaffoldBackgroundColor: const Color(0xFF1A1A2E), // Fallback
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          // Sci-fi font for headers
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      /* cardTheme: CardTheme(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.8),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ), */
      iconTheme: const IconThemeData(color: Colors.white),
      /* dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
        ),
        titleTextStyle: GoogleFonts.orbitron(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: GoogleFonts.outfit(
          color: Colors.white70,
          fontSize: 16,
        ),
      ), */
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: secondaryColor.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: child,
    );
  }
}
