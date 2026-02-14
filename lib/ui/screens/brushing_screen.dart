import 'dart:async';
import 'package:flutter/material.dart';

import 'package:percent_indicator/percent_indicator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/brushing_provider.dart';
import '../../utils/app_theme.dart';
import '../widgets/vibrant_card.dart';

class BrushingScreen extends ConsumerStatefulWidget {
  const BrushingScreen({super.key});

  @override
  ConsumerState<BrushingScreen> createState() => _BrushingScreenState();
}

class _BrushingScreenState extends ConsumerState<BrushingScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _brushingController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _brushingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  Future<void> _loadSettings() async {
    final val = await DatabaseService().getSetting('brushing_duration');
    final durationSec = int.tryParse(val ?? '300') ?? 300;
    // Only set duration if timer is not currently running to avoid resetting active session
    final currentState = ref.read(brushingProvider);
    if (!currentState.isRunning) {
      ref
          .read(brushingProvider.notifier)
          .setDuration(Duration(seconds: durationSec));
    }
  }

  @override
  void dispose() {
    _brushingController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _completeSession() async {
    // Award XP & Check Badges
    ref.read(userProvider.notifier).recordBrushing();

    // Play Sound
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/ding.mp3'));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }

    // Celebrate
    _confettiController.play();

    // Show Dialog
    if (mounted) {
      final userState = ref.read(userProvider);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E), // Solid dark background
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.secondaryColor.withValues(alpha: 0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Brossage Terminé !",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: AppTheme.textShadows,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10), // Reduced from 20
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Icon(
                    Icons.star_rounded,
                    size: 100,
                    color: AppTheme.warningColor,
                    shadows: [
                      Shadow(
                        color: AppTheme.warningColor.withValues(alpha: 0.6),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5), // Reduced from 20
                const Text(
                  "+50 XP",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: AppTheme.textShadows,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Série en cours : ${userState.streak} jours 🔥",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    shadows: AppTheme.textShadows,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      "Génial !",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildControlButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required double size,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary
              ? color.withValues(alpha: 0.85)
              : color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: isPrimary ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isPrimary ? 0.5 : 0.25),
              blurRadius: isPrimary ? 20 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isPrimary ? 40 : 26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brushingState = ref.watch(brushingProvider);
    final secondsRemaining = brushingState.remaining.inSeconds;
    final totalDuration = brushingState.total.inSeconds;
    final isRunning = brushingState.isRunning;

    // Debug: vérifier les dimensions disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.sizeOf(context);
        debugPrint('[BrushingScreen] Build - size: ${size.width}x${size.height}');
      }
    });

    // Listen for completion
    ref.listen(brushingProvider, (previous, next) {
      if (previous != null &&
          previous.isRunning &&
          !next.isRunning &&
          next.remaining == Duration.zero) {
        _completeSession();
      }
    });

    final userState = ref.watch(userProvider);
    final activeTheme = userState.activeTheme;
    final gradient =
        AppTheme.themes[activeTheme] ?? AppTheme.backgroundGradient;
    final imagePath = AppTheme.themeImagePaths[activeTheme];
    debugPrint(
      '[BrushingScreen] activeTheme=$activeTheme, imagePath=$imagePath',
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Brossage",
          style: TextStyle(
            color: Colors.white,
            shadows: AppTheme.textShadows,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          debugPrint(
            '[BrushingScreen] LayoutBuilder - constraints: '
            '${constraints.maxWidth}x${constraints.maxHeight}',
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              // Fond (évite le double Scaffold de AppBackground)
              Positioned.fill(
                child: imagePath != null
                    ? Image.asset(imagePath, fit: BoxFit.cover)
                    : Container(
                        decoration: BoxDecoration(gradient: gradient),
                      ),
              ),
              // Contenu
              SafeArea(
                child: Stack(
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
              // Contenu principal
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: SingleChildScrollView(
                    child: VibrantCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                              // Animation section
                              Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  const Text(
                                    '🦷',
                                    style: TextStyle(fontSize: 110),
                                  ),
                                  if (isRunning) ...[
                                    Positioned(
                                      top: -10,
                                      left: 20,
                                      child: ScaleTransition(
                                        scale: Tween(begin: 0.6, end: 1.2).animate(
                                          CurvedAnimation(
                                            parent: _brushingController,
                                            curve: Curves.easeInOut,
                                          ),
                                        ),
                                        child: const Text(
                                          '🫧',
                                          style: TextStyle(fontSize: 26),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 16,
                                      child: FadeTransition(
                                        opacity: _brushingController,
                                        child: const Text(
                                          '🫧',
                                          style: TextStyle(fontSize: 22),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 16,
                                      left: 12,
                                      child: ScaleTransition(
                                        scale: Tween(begin: 0.8, end: 0.4).animate(
                                          CurvedAnimation(
                                            parent: _brushingController,
                                            curve: Curves.elasticIn,
                                          ),
                                        ),
                                        child: const Text(
                                          '🫧',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (isRunning)
                                    AnimatedBuilder(
                                      animation: _brushingController,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            20.0 *
                                                (0.5 - _brushingController.value),
                                            0,
                                          ),
                                          child: Transform.rotate(
                                            angle: -0.2 +
                                                (0.4 * _brushingController.value),
                                            child: const Text(
                                              '🪥',
                                              style: TextStyle(fontSize: 84),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    Transform.translate(
                                      offset: const Offset(20, 12),
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: const Text(
                                          '🪥',
                                          style: TextStyle(fontSize: 84),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Timer (avec bordures comme la page d'accueil)
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  CircularPercentIndicator(
                                    radius: 120.0,
                                    lineWidth: 20.0,
                                    percent: (1.0 -
                                            (secondsRemaining /
                                                (totalDuration == 0
                                                    ? 1
                                                    : totalDuration)))
                                        .clamp(0.0, 1.0),
                                    center: Text(
                                      "${(secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(secondsRemaining % 60).toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: AppTheme.textShadows,
                                      ),
                                    ),
                                    progressColor: AppTheme.primaryColor,
                                    backgroundColor:
                                        AppTheme.primaryColor.withValues(
                                          alpha: 0.15,
                                        ),
                                    circularStrokeCap: CircularStrokeCap.round,
                                  ),
                                  // Bordure extérieure (240 = 2×radius)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: IgnorePointer(
                                        child: SizedBox(
                                          width: 240,
                                          height: 240,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Bordure intérieure
                                  Positioned(
                                    top: 20,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: IgnorePointer(
                                        child: SizedBox(
                                          width: 200,
                                          height: 200,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Message
                              Text(
                                isRunning
                                    ? "Brosse bien partout !"
                                    : "Prêt pour un sourire éclatant ?",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  shadows: AppTheme.textShadows,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              // Boutons de contrôle
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildControlButton(
                                    onTap: () {
                                      ref
                                          .read(brushingProvider.notifier)
                                          .resetTimer();
                                    },
                                    icon: Icons.refresh,
                                    color: AppTheme.primaryColor,
                                    size: 58,
                                  ),
                                  const SizedBox(width: 36),
                                  _buildControlButton(
                                    onTap: () {
                                      if (isRunning) {
                                        ref
                                            .read(brushingProvider.notifier)
                                            .stopTimer();
                                      } else {
                                        ref
                                            .read(brushingProvider.notifier)
                                            .startTimer();
                                      }
                                    },
                                    icon: isRunning ? Icons.pause : Icons.play_arrow,
                                    color: isRunning
                                        ? AppTheme.warningColor
                                        : AppTheme.successColor,
                                    size: 80,
                                    isPrimary: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ),
                    ),
                  ),
                ),
            ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
