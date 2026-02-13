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
    final durationSec = int.tryParse(val ?? '120') ?? 120;
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
                Text(
                  "+50 XP",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                    shadows: [
                      Shadow(
                        color: AppTheme.accentColor.withValues(alpha: 0.6),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Série en cours : ${userState.streak} jours 🔥",
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
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

  @override
  Widget build(BuildContext context) {
    final brushingState = ref.watch(brushingProvider);
    final secondsRemaining = brushingState.remaining.inSeconds;
    final totalDuration = brushingState.total.inSeconds;
    final isRunning = brushingState.isRunning;

    // Listen for completion
    ref.listen(brushingProvider, (previous, next) {
      if (previous != null &&
          previous.isRunning &&
          !next.isRunning &&
          next.remaining == Duration.zero) {
        _completeSession();
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("Brossage")),
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Tooth Emoji
                      const Text('🦷', style: TextStyle(fontSize: 100)),
                      // Foam / Bubbles Animation
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
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 15,
                          child: FadeTransition(
                            opacity: _brushingController,
                            child: const Text(
                              '🫧',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 15,
                          left: 10,
                          child: ScaleTransition(
                            scale: Tween(begin: 0.8, end: 0.4).animate(
                              CurvedAnimation(
                                parent: _brushingController,
                                curve: Curves.elasticIn,
                              ),
                            ),
                            child: const Text(
                              '🫧',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                      // Animated Toothbrush
                      if (isRunning)
                        AnimatedBuilder(
                          animation: _brushingController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                20.0 *
                                    (0.5 -
                                        _brushingController
                                            .value), // Move left-right
                                0,
                              ),
                              child: Transform.rotate(
                                angle:
                                    -0.2 +
                                    (0.4 *
                                        _brushingController
                                            .value), // Rotate slightly
                                child: const Text(
                                  '🪥',
                                  style: TextStyle(fontSize: 80),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        Transform.translate(
                          offset: const Offset(20, 10),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: const Text(
                              '🪥',
                              style: TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  CircularPercentIndicator(
                    radius: 130.0, // Increased from 100.0
                    lineWidth: 20.0, // Increased from 15.0
                    percent:
                        (1.0 -
                                (secondsRemaining /
                                    (totalDuration == 0 ? 1 : totalDuration)))
                            .clamp(0.0, 1.0),
                    center: Text(
                      "${(secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(secondsRemaining % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 44, // Reduced from 50
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    progressColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset Button
                      FloatingActionButton(
                        heroTag: "reset_btn",
                        onPressed: () {
                          ref.read(brushingProvider.notifier).resetTimer();
                        },
                        backgroundColor: Colors.white24,
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Play/Pause Button
                      FloatingActionButton.large(
                        heroTag: "play_btn",
                        onPressed: () {
                          if (isRunning) {
                            ref.read(brushingProvider.notifier).stopTimer();
                          } else {
                            ref.read(brushingProvider.notifier).startTimer();
                          }
                        },
                        backgroundColor: isRunning
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                        child: Icon(
                          isRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(width: 96), // Balance the row visually
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    isRunning
                        ? "Brosse bien partout !"
                        : "Prêt pour un sourire éclatant ?",
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50), // Push content up slightly
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
