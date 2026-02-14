import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';

class AppTheme {
  // Neon Palette
  static const Color primaryColor = Color(0xFF00F0FF); // Neon Cyan
  static const Color secondaryColor = Color(
    0xFFBC13FE,
  ); // Neon Purple (Ajusté pour meilleur contraste)
  static const Color accentColor = Color(0xFFFF0099); // Neon Pink
  static const Color successColor = Color(0xFF39FF14); // Neon Green
  static const Color warningColor = Color(0xFFFFD300); // Neon Yellow
  static const Color errorColor = Color(0xFFFF3131); // Neon Red

  static const List<Shadow> textShadows = [
    Shadow(
      color: Colors.black, // Noir pur plus opaque par défaut
      offset: Offset(0, 1),
      blurRadius: 4, // Un peu plus diffus
    ),
    Shadow(
      color: Colors.black87, // Deuxième couche pour renforcer
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  // Rich Premium Gradients
  static const Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F0C29), // Night Sky
      Color(0xFF302B63), // Royal blue
      Color(0xFF24243E), // Deep space
    ],
  );

  static const Gradient spaceGradient = RadialGradient(
    center: Alignment(0.7, -0.6),
    radius: 1.5,
    colors: [
      Color(0xFF2B1055), // Deep Purple glow
      Color(0xFF000000), // Pure Black
    ],
  );

  static const Gradient auroraGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF00416A), // Dark blue
      Color(0xFF00B09B), // Aurora green
      Color(0xFF0F0C29), // Back to dark
    ],
    stops: [0.0, 0.4, 1.0],
  );

  static const Gradient sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2C3E50), // Midnight blue
      Color(0xFFFD746C), // Sunset coral
      Color(0xFF0F2027), // Deep abyss
    ],
    stops: [0.1, 0.5, 1.0],
  );

  static const Gradient midnightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF232526), Color(0xFF414345)],
  );

  static const Gradient desertGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFFEB47B), Color(0xFF3F2B96)],
  );

  static const Gradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
  );

  static const Gradient cyberPinkGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [Color(0xFFFF00CC), Color(0xFF333399)],
  );

  static const Gradient oceanGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
  );

  static const Gradient volcanoGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFFf12711), Color(0xFFf5af19)],
  );

  static Map<String, Gradient> themes = {
    'default_neon': backgroundGradient,
    'deep_space': spaceGradient,
    'aurora': auroraGradient,
    'sunset': sunsetGradient,
    'midnight': midnightGradient,
    'desert': desertGradient,
    'emerald': emeraldGradient,
    'cyber_pink': cyberPinkGradient,
    'ocean': oceanGradient,
    'volcano': volcanoGradient,
  };

  static Map<String, String> themeNames = {
    'default_neon': 'Néon Classique',
    'deep_space': 'Espace Profond',
    'aurora': 'Aurore Boréale',
    'sunset': 'Coucher de Soleil',
    'midnight': 'Minuit Tech',
    'desert': 'Désert Cyber',
    'emerald': 'Rêve Émeraude',
    'cyber_pink': 'Vibration Rose',
    'ocean': 'Plongée Bleue',
    'volcano': 'Fureur Volcanique',
  };

  static Map<String, int> themeUnlockLevels = {
    'default_neon': 1,
    'deep_space': 2,
    'aurora': 3,
    'sunset': 4,
    'midnight': 5,
    'desert': 6,
    'emerald': 7,
    'cyber_pink': 8,
    'ocean': 9,
    'volcano': 10,
  };

  static Map<String, String> themeImagePaths = {
    'deep_space': 'assets/images/themes/deep_space.png',
    'midnight': 'assets/images/themes/tech_minute.png',
    'desert': 'assets/images/themes/cyber_desert.png',
    'aurora': 'assets/images/themes/boreal_aurore.png',
    'volcano': 'assets/images/themes/volcan.png',
    'cyber_pink': 'assets/images/themes/rose.png',
    'emerald': 'assets/images/themes/emerald_dream.png',
    'ocean': 'assets/images/themes/ocean_dive.png',
    'sunset': 'assets/images/themes/sunset.png',
    'default_neon': 'assets/images/themes/neon_default.png',
  };

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
        surface: Color(0xFF1E1E2E), // Solid surface color for M3 components
        error: errorColor,
      ),
      textTheme: GoogleFonts.orbitronTextTheme(
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
      iconTheme: const IconThemeData(color: Colors.white),
      dialogTheme: DialogThemeData(
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
        contentTextStyle: GoogleFonts.orbitron(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
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
          textStyle: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class AppBackground extends ConsumerWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(userProvider).activeTheme;
    final gradient =
        AppTheme.themes[activeTheme] ?? AppTheme.backgroundGradient;
    final imagePath = AppTheme.themeImagePaths[activeTheme];
    debugPrint('[AppBackground] theme=$activeTheme, imagePath=$imagePath');

    // Décoder l'image à la taille d'affichage (évite de bloquer le main thread avec de grosses images)
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (size.width * dpr).round().clamp(1, 1080);
    final cacheHeight = (size.height * dpr).round().clamp(1, 1920);

    return Scaffold(
      body: Stack(
        children: [
          // Background: Image if exists, otherwise Gradient
          Positioned.fill(
            child: imagePath != null
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    cacheWidth: cacheWidth,
                    cacheHeight: cacheHeight,
                    frameBuilder: (context, child, frame, _) {
                      // Afficher le gradient immédiatement pendant le chargement
                      if (frame == null) {
                        return Container(
                            decoration: BoxDecoration(gradient: gradient));
                      }
                      return child;
                    },
                  )
                : Container(decoration: BoxDecoration(gradient: gradient)),
          ),

          // Subtle Stardust effect (only on gradients usually, but kept for all if needed)
          if (imagePath == null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _StarPainter(
                    seed: activeTheme.hashCode,
                    opacity: 0.15,
                  ),
                ),
              ),
            ),

          // Content
          child,
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final int seed;
  final double opacity;

  _StarPainter({required this.seed, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);

    // Simple deterministic pseudo-random stars
    for (int i = 0; i < 100; i++) {
      final double x = ((i * 137 + seed) % 1000) / 1000 * size.width;
      final double y = ((i * 251 + seed) % 1000) / 1000 * size.height;
      final double radius = ((i % 3) + 1) / 2;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => seed != oldDelegate.seed;
}
