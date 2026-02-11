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

class _BrushingScreenState extends ConsumerState<BrushingScreen> {
  late Timer _timer;
  int _secondsRemaining = 120; // 2 minutes
  bool _isRunning = false;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _loadSettings() async {
    final val = await DatabaseService().getSetting('brushing_duration');
    final duration = int.tryParse(val ?? '120') ?? 120;
    setState(() {
      _secondsRemaining = duration;
      _totalDuration = duration;
    });
  }

  // Track initial total to calculate progress correctly
  int _totalDuration = 120;

  @override
  void dispose() {
    _timer.cancel();
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
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _completeSession();
        }
      });
    });
  }

  Future<void> _completeSession() async {
    _timer.cancel();
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
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Brossage Terminé !"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("+50 XP"),
              const SizedBox(height: 10),
              Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_touohxv0.json', // Star animation
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
    _timer.cancel();
    setState(() {
      _isRunning = false;
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
                  Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_metk4x85.json',
                    height: 200,
                    animate: _isRunning,
                  ),
                  const SizedBox(height: 40),
                  CircularPercentIndicator(
                    radius: 100.0,
                    lineWidth: 15.0,
                    percent: (1.0 - (_secondsRemaining / _totalDuration)).clamp(
                      0.0,
                      1.0,
                    ),
                    center: Text(
                      "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    progressColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton.large(
                        onPressed: _isRunning ? _stopTimer : _startTimer,
                        backgroundColor: _isRunning
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                        child: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isRunning)
                    const Text(
                      "Brosse bien partout !",
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
