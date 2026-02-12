import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../providers/timer_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/date_utils.dart';
import '../../utils/app_theme.dart';
import '../../utils/session_utils.dart';
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
        leading: userState.streak > 0
            ? Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BadgesScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _getStreakColor(
                          userState.streak,
                        ).withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getStreakColor(
                            userState.streak,
                          ).withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          userState.streak >= 3
                              ? Icons.local_fire_department
                              : Icons.ac_unit,
                          color: _getStreakColor(userState.streak),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${userState.streak}",
                          style: TextStyle(
                            color: _getStreakColor(userState.streak),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            shadows: [
                              Shadow(
                                color: _getStreakColor(
                                  userState.streak,
                                ).withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        leadingWidth: 85,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),

              child: Column(
                children: [
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
                                      !SessionUtils.stickers.containsKey(
                                        stickerId,
                                      )) {
                                    return const SizedBox.shrink();
                                  }

                                  final data =
                                      SessionUtils.stickers[stickerId]!;

                                  return GestureDetector(
                                    onLongPress: () {
                                      if (session.id != null) {
                                        _showEditStickerDialog(
                                          context,
                                          ref,
                                          session.id!,
                                        );
                                      }
                                    },
                                    onTap:
                                        () {}, // Triggered by Tooltip triggerMode
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
                                          triggerMode: TooltipTriggerMode.tap,
                                          preferBelow: true,
                                          verticalOffset: 20,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFEEEEEE,
                                            ).withValues(alpha: 0.95),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          message:
                                              "${_formatDuration(session.duration)} - ${data['label']}",
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.1,
                                              ), // Effet verre
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      (data['color'] as Color)
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                              border: Border.all(
                                                color:
                                                    data['color']
                                                        as Color, // Bordure solide
                                                width: 1.5,
                                              ),
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
                          radius: 115.0,
                          lineWidth: 20.0,
                          percent: progress,
                          center: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatDuration(totalDuration),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32.0,
                                      color: Colors.white,
                                      shadows: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Text(
                                  "Aujourd'hui",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          (totalDuration.inHours >=
                                              timerState.dailyGoal)
                                          ? AppTheme.successColor
                                          : AppTheme.primaryColor,
                                    ),
                                  ),
                                  child: Text(
                                    "Objectif: ${timerState.dailyGoal}h",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          (totalDuration.inHours >=
                                              timerState.dailyGoal)
                                          ? AppTheme.successColor
                                          : AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          progressColor:
                              (totalDuration.inHours >= timerState.dailyGoal)
                              ? AppTheme.successColor
                              : (progress >= 0.5
                                    ? AppTheme.primaryColor
                                    : AppTheme.accentColor),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true,
                          animateFromLastPercent: true,
                          footer: Padding(
                            padding: const EdgeInsets.only(top: 6.0),

                            child: Text(
                              (totalDuration.inHours >= timerState.dailyGoal)
                                  ? "OBJECTIF ATTEINT"
                                  : "EN COURS...",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Les 3 derniers jours (NOUVEAU - intégré ici)
                        _build3DaysHistory(timerState),

                        const SizedBox(height: 12),

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
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              GestureDetector(
                                onTap: () => _showXPInfo(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.warningColor.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.help_outline,
                                        size: 14,
                                        color: AppTheme.warningColor,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Comment gagner de l'XP ?",
                                        style: TextStyle(
                                          color: AppTheme.warningColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

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
                                    ? AppTheme.errorColor
                                    : AppTheme.successColor,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isRunning
                                          ? [AppTheme.errorColor, Colors.black]
                                          : [
                                              AppTheme.successColor,
                                              Colors.green.shade900,
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isRunning
                                                    ? AppTheme.errorColor
                                                    : AppTheme.successColor)
                                                .withValues(alpha: 0.6),
                                        blurRadius: 25,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    isRunning
                                        ? Icons.stop
                                        : Icons.power_settings_new,
                                    size: 45,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              isRunning ? "ARRÊTER" : "DÉMARRER",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.5,
                                color: isRunning
                                    ? AppTheme.errorColor
                                    : AppTheme.successColor,
                                shadows: [
                                  BoxShadow(
                                    color: (isRunning
                                        ? AppTheme.errorColor
                                        : AppTheme.successColor),
                                    blurRadius: 10,
                                  ),
                                ],
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
                                if (isRunning) {
                                  _showBrushingWarning(context);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BrushingScreen(),
                                    ),
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: isRunning
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : AppTheme.primaryColor.withValues(
                                          alpha: 0.2,
                                        ), // Cyan tint
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isRunning
                                        ? Colors.white24
                                        : AppTheme.primaryColor,
                                    width: 2,
                                  ), // Solid border
                                  boxShadow: [
                                    if (!isRunning)
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.cleaning_services,
                                  size: 45,
                                  color: isRunning
                                      ? Colors.white24
                                      : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              "BROSSAGE",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.5,
                                color: isRunning
                                    ? Colors.white24
                                    : Colors.white70,
                                shadows: [
                                  if (!isRunning)
                                    const BoxShadow(
                                      color: AppTheme.primaryColor,
                                      blurRadius: 10,
                                    ),
                                ],
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

  Color _getStreakColor(int streak) {
    if (streak >= 7) return AppTheme.accentColor;
    if (streak >= 3) return AppTheme.secondaryColor;
    return AppTheme.primaryColor;
  }

  Widget _build3DaysHistory(TimerState timerState) {
    final history = timerState.recentHistory;
    final days = [1, 2, 3];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "HISTORIQUE (3J)",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: days.reversed.map((daysAgo) {
              final refDate = DateTime.now().subtract(Duration(days: daysAgo));
              final reportingDate = OrthoDateUtils.getReportingDate(refDate);
              final minutes = history[reportingDate] ?? 0;
              final targetMin = timerState.dailyGoal * 60;
              final percentage = (minutes / targetMin).clamp(0.0, 1.0);

              Color barColor = AppTheme.errorColor;
              if (percentage >= 1.0) {
                barColor = AppTheme.successColor;
              } else if (percentage >= 0.5) {
                barColor = AppTheme.warningColor;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: percentage == 0 ? 0.05 : percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: barColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "J-$daysAgo",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${(minutes / 60).toStringAsFixed(1)}h",
                        style: TextStyle(fontSize: 10, color: Colors.white38),
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

  String _formatDuration(Duration d) => SessionUtils.formatDuration(d);

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
              children: SessionUtils.stickers.entries.map((entry) {
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
                          color: Colors.white.withValues(
                            alpha: 0.1,
                          ), // Effet verre
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (data['color'] as Color).withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                          border: Border.all(
                            color: data['color'] as Color, // Bordure solide
                            width: 2,
                          ),
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
                children: SessionUtils.stickers.entries.map((entry) {
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
                            color: Colors.white.withValues(
                              alpha: 0.1,
                            ), // Effet verre
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (data['color'] as Color).withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                            border: Border.all(
                              color: data['color'] as Color, // Bordure solide
                              width: 2,
                            ),
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

  void _showXPInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        title: const Text(
          "Système d'XP",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Gagne des points pour devenir une légende :",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 20),
              _buildXPInfoCard(
                Icons.timer_outlined,
                "Port de l'appareil",
                "10 XP / heure",
                AppTheme.primaryColor,
              ),
              _buildXPInfoCard(
                Icons.brush_outlined,
                "Brossage des dents",
                "50 XP / session",
                AppTheme.successColor,
              ),
              _buildXPInfoCard(
                Icons.trending_up,
                "Niveaux",
                "1 montée tous les 1000 XP",
                AppTheme.secondaryColor,
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
              ),
              child: const Text("Cool !"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPInfoCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBrushingWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Appareil porté !"),
        content: const Text(
          "Tu ne peux pas te brosser les dents avec ton appareil. 😉\n\nArrête d'abord ton suivi de port pour lancer le brossage !",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Compris !"),
          ),
        ],
      ),
    );
  }
}
