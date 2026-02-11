import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../providers/timer_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/date_utils.dart';
import '../../utils/app_theme.dart';
import '../widgets/vibrant_card.dart';

import 'brushing_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'badges_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final userState = ref.watch(userProvider);
    final isRunning = timerState.isRunning;

    // Total duration: stored daily total + current session
    final totalDuration =
        timerState.dailyTotalDuration + timerState.currentSessionDuration;

    // Target: Dynamic based on settings
    final targetMinutes = timerState.dailyGoal * 60;
    final progress = (totalDuration.inMinutes / targetMinutes).clamp(0.0, 1.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'OrthoQuest',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Badge de streak uniquement (compact)
                  if (userState.streak > 0) _buildStreakBadge(userState),
                  if (userState.streak > 0) const SizedBox(height: 24),

                  // Main Card avec Sessions + Gauge + 3 derniers jours + Level
                  VibrantCard(
                    child: Column(
                      children: [
                        // Sessions du jour en haut (icônes)
                        if (timerState.dailySessions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: timerState.dailySessions.length,
                                itemBuilder: (context, index) {
                                  final session =
                                      timerState.dailySessions[index];
                                  final stickerId = session.stickerId;

                                  if (stickerId == null ||
                                      !_stickers.containsKey(stickerId)) {
                                    return const SizedBox.shrink();
                                  }

                                  final data = _stickers[stickerId]!;

                                  return GestureDetector(
                                    onTap: () {
                                      if (session.id != null) {
                                        _showEditStickerDialog(
                                          context,
                                          ref,
                                          session.id!,
                                        );
                                      }
                                    },
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: Duration(
                                        milliseconds: 400 + (index * 100),
                                      ),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: child,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Tooltip(
                                          message:
                                              "${_formatDuration(session.duration)} - ${data['label']}",
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: (data['color'] as Color)
                                                  .withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              data['icon'] as IconData,
                                              color: data['color'] as Color,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        // Jauge circulaire principale
                        CircularPercentIndicator(
                          radius: 110.0,
                          lineWidth: 18.0,
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
                              const Text(
                                "Aujourd'hui",
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      totalDuration.inHours >=
                                          timerState.dailyGoal
                                      ? Colors.green.withAlpha(30)
                                      : Colors.blue.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Objectif: ${timerState.dailyGoal}h",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        totalDuration.inHours >=
                                            timerState.dailyGoal
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          progressColor:
                              totalDuration.inHours >= timerState.dailyGoal + 1
                              ? Colors.blue.shade700
                              : (totalDuration.inHours >= timerState.dailyGoal
                                    ? Colors.green
                                    : (progress >= 0.5
                                          ? Colors.orange
                                          : Colors.redAccent)),
                          backgroundColor: Colors.grey.shade100,
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true,
                          animateFromLastPercent: true,
                        ),

                        const SizedBox(height: 20),

                        // Les 3 derniers jours (NOUVEAU - intégré ici)
                        _build3DaysHistory(timerState),

                        const SizedBox(height: 20),

                        // Level Bar inside the main card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BadgesScreen(),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearPercentIndicator(
                                  lineHeight: 10.0,
                                  percent: (userState.xp % 1000) / 1000,
                                  backgroundColor: Colors.grey.shade100,
                                  progressColor: Colors.blueAccent,
                                  barRadius: const Radius.circular(10),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Niveau ${userState.level} • ${userState.xp % 1000} / 1000 XP",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Boutons en Row (côte à côte)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Start/Stop Button
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (isRunning) {
                                  _showStopDialog(context, ref);
                                } else {
                                  ref
                                      .read(timerProvider.notifier)
                                      .startSession();
                                }
                              },
                              child: AvatarGlow(
                                animate: isRunning,
                                glowColor: isRunning
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: isRunning
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isRunning
                                                    ? Colors.redAccent
                                                    : Colors.greenAccent)
                                                .withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
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
                            const SizedBox(height: 8),
                            Text(
                              isRunning ? "En cours..." : "Démarrer",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Brushing Button
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BrushingScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.secondaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.cleaning_services,
                                  size: 40,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Brossage",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakBadge(UserState userState) {
    final streak = userState.streak;
    Color flameColor = Colors.blue;
    if (streak >= 7) {
      flameColor = Colors.red;
    } else if (streak >= 3) {
      flameColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: flameColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: flameColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            streak >= 3 ? Icons.local_fire_department : Icons.ac_unit,
            color: flameColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            "$streak jours",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: flameColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DaysHistory(TimerState timerState) {
    final history = timerState.recentHistory;
    final days = [1, 2, 3];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "3 derniers jours",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: days.reversed.map((daysAgo) {
              final refDate = DateTime.now().subtract(Duration(days: daysAgo));
              final reportingDate = OrthoDateUtils.getReportingDate(refDate);
              final minutes = history[reportingDate] ?? 0;
              final targetMin = timerState.dailyGoal * 60;
              final percentage = (minutes / targetMin).clamp(0.0, 1.0);

              Color barColor = Colors.redAccent;
              if (percentage >= 1.0) {
                barColor = Colors.green;
              } else if (percentage >= 0.5) {
                barColor = Colors.orange;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "J-$daysAgo",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${(minutes / 60).toStringAsFixed(1)}h",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
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

  // Map of Sticker ID to Label and Icon
  static const Map<int, Map<String, dynamic>> _stickers = {
    0: {
      'icon': Icons.sentiment_very_satisfied,
      'label': 'Super !',
      'color': Colors.green,
    },
    1: {
      'icon': Icons.sentiment_satisfied,
      'label': 'Bien',
      'color': Colors.lightGreen,
    },
    2: {
      'icon': Icons.sentiment_neutral,
      'label': 'Moyen',
      'color': Colors.amber,
    },
    3: {
      'icon': Icons.sentiment_dissatisfied,
      'label': 'Douleur',
      'color': Colors.orangeAccent,
    },
    4: {
      'icon': Icons.sentiment_very_dissatisfied,
      'label': 'Difficile',
      'color': Colors.red,
    },
    5: {'icon': Icons.bed, 'label': 'Nuit', 'color': Colors.indigo},
  };

  void _showStopDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bravo !"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Comment s'est passée cette session ?"),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _stickers.entries.map((entry) {
                final id = entry.key;
                final data = entry.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        ref
                            .read(timerProvider.notifier)
                            .stopSession(stickerId: id);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (data['color'] as Color).withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          data['icon'] as IconData,
                          color: data['color'] as Color,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['label'] as String,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(timerProvider.notifier).stopSession(); // No sticker
              Navigator.pop(context);
            },
            child: const Text("Passer"),
          ),
        ],
      ),
    );
  }

  void _showEditStickerDialog(
    BuildContext context,
    WidgetRef ref,
    int sessionId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier la session"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choisis une nouvelle icône :"),
            const SizedBox(height: 20),
            SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _stickers.entries.map((entry) {
                  final id = entry.key;
                  final data = entry.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          ref
                              .read(timerProvider.notifier)
                              .updateSessionSticker(sessionId, id);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (data['color'] as Color).withValues(
                              alpha: 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            data['icon'] as IconData,
                            color: data['color'] as Color,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['label'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
        ],
      ),
    );
  }
}
