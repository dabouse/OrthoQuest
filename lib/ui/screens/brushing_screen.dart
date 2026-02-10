import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/database_service.dart';

class BrushingScreen extends StatefulWidget {
  const BrushingScreen({super.key});

  @override
  State<BrushingScreen> createState() => _BrushingScreenState();
}

class _BrushingScreenState extends State<BrushingScreen> {
  late int _totalSeconds;
  int _remainingSeconds = 120; // Default fallback
  Timer? _timer;
  bool _isRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Placeholder Lottie URL - replace with local asset in production
  final String _lottieUrl =
      'https://assets10.lottiefiles.com/packages/lf20_33asonmr.json';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final durationStr = await DatabaseService().getSetting('brushing_duration');
    setState(() {
      _totalSeconds = int.tryParse(durationStr ?? '120') ?? 120;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_remainingSeconds == 0) {
        // Reset if finished
        setState(() => _remainingSeconds = _totalSeconds);
      }
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _finishTimer();
        }
      });
    }
  }

  void _finishTimer() async {
    _timer?.cancel();
    setState(() => _isRunning = false);

    // Play sound
    try {
      await _audioPlayer.play(AssetSource('sounds/ding.mp3'));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Brossage terminé !"),
          content: const Text("Tes dents sont toutes propres ! ✨"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
              },
              child: const Text("Super !"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Prevent division by zero
    double percent = _totalSeconds > 0
        ? (_totalSeconds - _remainingSeconds) / _totalSeconds
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Timer Brossage"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation
            SizedBox(
              height: 250,
              child: Lottie.network(
                _lottieUrl,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.cleaning_services,
                    size: 100,
                    color: Colors.blueAccent,
                  );
                },
                animate: _isRunning,
              ),
            ),
            const SizedBox(height: 40),

            // Timer Gauge
            CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 15.0,
              percent: percent.clamp(0.0, 1.0),
              center: Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              progressColor: Colors.blue,
              backgroundColor: Colors.blue.shade100,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animateFromLastPercent: true,
            ),

            const SizedBox(height: 50),

            // Controls
            FloatingActionButton.large(
              onPressed: _toggleTimer,
              backgroundColor: _isRunning ? Colors.orange : Colors.blue,
              child: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _timer?.cancel();
                setState(() {
                  _isRunning = false;
                  _remainingSeconds = _totalSeconds;
                });
              },
              child: const Text("Réinitialiser"),
            ),
          ],
        ),
      ),
    );
  }
}
