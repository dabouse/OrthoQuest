import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../providers/timer_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/date_utils.dart';
import '../../../utils/session_utils.dart';
import '../../screens/rewards_screen.dart';
import '../session_actions_sheet.dart';

class DailyProgressCard extends ConsumerWidget {
  const DailyProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final userState = ref.watch(userProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final s = (screenHeight / 950.0).clamp(0.7, 1.2);

    // Session en cours : clipper à la fenêtre du jour actuel
    Duration todayCurrentSession = timerState.currentSessionDuration;
    if (timerState.isRunning && timerState.startTime != null) {
      final dayStart = OrthoDateUtils.getDayStart(
        DateTime.now(),
        dayEndHour: timerState.dayEndHour,
      );
      if (timerState.startTime!.isBefore(dayStart)) {
        todayCurrentSession = DateTime.now().difference(dayStart);
        if (todayCurrentSession.isNegative) {
          todayCurrentSession = Duration.zero;
        }
      }
    }

    // Total duration: sessions terminées (clippées) + session en cours (clippée)
    final totalDuration =
        timerState.dailyTotalDuration + todayCurrentSession;

    // Target: Dynamic based on settings
    final targetMinutes = timerState.dailyGoal * 60;
    final progress = (totalDuration.inMinutes / targetMinutes).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              // Sessions du jour en haut (toujours présent pour stabilité)
              _buildSessionList(context, ref, timerState, s),

              // Jauge circulaire principale
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercle décoratif extérieur (même diamètre que l'indicateur)
                        IgnorePointer(
                          child: SizedBox(
                            width: 230 * s,
                            height: 230 * s,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Cercle décoratif intérieur
                        IgnorePointer(
                          child: SizedBox(
                            width: 190 * s,
                            height: 190 * s,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Indicateur circulaire (par-dessus les cercles décoratifs)
                        CircularPercentIndicator(
                          radius: 115.0 * s,
                          lineWidth: 20.0 * s,
                          percent: progress,
                          center: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    SessionUtils.formatDuration(totalDuration),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28.0,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                        Shadow(
                                          color: AppTheme.primaryColor,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Text(
                                  "Aujourd'hui",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    shadows: AppTheme.textShadows,
                                  ),
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
                                          (totalDuration.inHours >= timerState.dailyGoal)
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
                                          (totalDuration.inHours >= timerState.dailyGoal)
                                          ? AppTheme.successColor
                                          : AppTheme.primaryColor,
                                      shadows: AppTheme.textShadows,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          progressColor: (totalDuration.inHours >= timerState.dailyGoal)
                              ? AppTheme.successColor
                              : (progress >= 0.5
                                    ? AppTheme.primaryColor
                                    : AppTheme.accentColor),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true,
                          animateFromLastPercent: true,
                        ),
                      ],
                    ),
                    // Footer sorti du CircularPercentIndicator pour ne pas perturber le Stack
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        (totalDuration.inMinutes >= targetMinutes)
                            ? "OBJECTIF ATTEINT"
                            : (timerState.isRunning ? "EN COURS..." : "EN ATTENTE"),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white,
                          fontSize: 10,
                          shadows: AppTheme.textShadows,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Petit bouton de personnalisation en haut à droite - COULEUR JAUNE NÉON VOYANTE
        Positioned(
          top: -5,
          right: -5,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RewardsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.warningColor.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warningColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.palette_outlined,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  if (userState.hasUnseenReward)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.errorColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    WidgetRef ref,
    TimerState timerState,
    double s,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * s),
      child: SizedBox(
        height: 36 * s,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: timerState.dailySessions.length,
          itemBuilder: (context, index) {
            final session = timerState.dailySessions[index];
            final stickerId = session.stickerId;

            if (stickerId == null ||
                !SessionUtils.stickers.containsKey(stickerId)) {
              return const SizedBox.shrink();
            }

            final data = SessionUtils.stickers[stickerId]!;

            return GestureDetector(
              onLongPress: () {
                if (session.id != null && session.endTime != null) {
                  showSessionActionsSheet(context, ref, session);
                }
              },
              onTap: () {},
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    preferBelow: true,
                    verticalOffset: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    message:
                        "${SessionUtils.formatDuration(session.duration)} - ${data['label']}",
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (data['color'] as Color).withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: data['color'] as Color,
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
    );
  }

}
