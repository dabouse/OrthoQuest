import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../providers/timer_provider.dart';
import '../widgets/sticker_grid.dart';
import 'brushing_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final isRunning = timerState.isRunning;

    // Total duration: stored daily total + current session
    final totalDuration =
        timerState.dailyTotalDuration + timerState.currentSessionDuration;

    // Target: 13 hours (in minutes) = 13 * 60 = 780
    const targetMinutes = 13 * 60;
    final progress = (totalDuration.inMinutes / targetMinutes).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'OrthoQuest',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart), // Changed to chart icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Stats (Streaks placeholder)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStreakBadge(),
                  if (isRunning)
                    Text(
                      "Debug: ${timerState.currentSessionDuration.inSeconds}s",
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Main Gauge
            Center(
              child: CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 20.0,
                percent: progress,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDuration(totalDuration),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32.0,
                      ),
                    ),
                    const Text("Aujourd'hui"),
                  ],
                ),
                progressColor: Colors.purple,
                backgroundColor: Colors.purple.shade100,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
              ),
            ),

            const SizedBox(height: 60),

            // Start/Stop Button
            GestureDetector(
              onTap: () {
                if (isRunning) {
                  _showStopDialog(context, ref);
                } else {
                  ref.read(timerProvider.notifier).startSession();
                }
              },
              child: AvatarGlow(
                animate: isRunning,
                glowColor: isRunning ? Colors.redAccent : Colors.greenAccent,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isRunning ? Colors.redAccent : Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRunning ? Icons.stop : Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isRunning ? "En cours..." : "Démarrer",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),

            const Spacer(),

            // Notes Button
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await showModalBottomSheet<int>(
                        context: context,
                        builder: (context) => const StickerGrid(),
                      );
                    },
                    icon: const Icon(Icons.emoji_emotions),
                    label: const Text("Note"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrushingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.cleaning_services,
                    ), // Toothbrush icon proxy
                    label: const Text("Brossage"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.orange),
          SizedBox(width: 5),
          Text(
            "3 Jours de suite !", // This should be dynamic
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours}h$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showStopDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bravo !"),
        content: const Text("Comment s'est passée cette session ?"),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(timerProvider.notifier).stopSession(); // No sticker
              Navigator.pop(context);
            },
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }
}
