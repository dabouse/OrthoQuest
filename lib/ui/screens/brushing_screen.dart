import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';

class BrushingScreen extends ConsumerStatefulWidget {
  const BrushingScreen({super.key});

  @override
  ConsumerState<BrushingScreen> createState() => _BrushingScreenState();
}

class _BrushingScreenState extends ConsumerState<BrushingScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _secondsRemaining = 120; // 2 minutes
  bool _isRunning = false;
  late ConfettiController _confettiController;
  late AnimationController _brushingController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Track initial total to calculate progress correctly
  int _totalDuration = 120;

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
    final duration = int.tryParse(val ?? '120') ?? 120;
    if (mounted) {
      setState(() {
        _secondsRemaining = duration;
        _totalDuration = duration;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _brushingController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _completeSession();
          }
        });
      }
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isRunning = false;
        _secondsRemaining = _totalDuration;
      });

      // Award XP & Check Badges
      ref.read(userProvider.notifier).recordBrushing();

      // Play Sound
      try {
        // Ensure asset is declared in pubspec.yaml
        await _audioPlayer.play(AssetSource('sounds/ding.mp3'));
      } catch (e) {
        debugPrint("Error playing sound: $e");
      }

      // Celebrate
      _confettiController.play();

      // Show Dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Brossage Terminé !"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("+50 XP"),
              const SizedBox(height: 10),
              Lottie.asset(
                'assets/animations/star_success.json', // Star animation
                height: 100,
                repeat: false,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back home
              },
              child: const Text("Super !"),
            ),
          ],
        ),
      );
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _totalDuration;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      // Animated Toothbrush
                      if (_isRunning)
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
                    percent: (1.0 - (_secondsRemaining / _totalDuration)).clamp(
                      0.0,
                      1.0,
                    ),
                    center: Text(
                      "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 50, // Increased from 40
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
                        onPressed: _resetTimer,
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
                        onPressed: _isRunning ? _stopTimer : _startTimer,
                        backgroundColor: _isRunning
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                        child: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(width: 96), // Balance the row visually
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _isRunning
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
