import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/timer_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/date_utils.dart';

class HistoryCard extends ConsumerWidget {
  const HistoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
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
          const SizedBox(height: 12),
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
}
