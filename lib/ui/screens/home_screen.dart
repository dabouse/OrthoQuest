import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';
import '../widgets/vibrant_card.dart';
import '../widgets/home/daily_progress_card.dart';
import '../widgets/home/action_buttons.dart';
import '../widgets/home/history_card.dart';
import '../widgets/home/level_bar.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'badges_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'OrthoQuest',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BadgesScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        : Icons
                              .calendar_today, // Changed from ac_unit to calendar for 0
                    color: _getStreakColor(userState.streak),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${userState.streak}",
                    style: TextStyle(
                      color: _getStreakColor(userState.streak),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
        ),
        leadingWidth: 85,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
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
                  // Main Card wrapped in VibrantCard
                  const VibrantCard(
                    child: Column(
                      children: [
                        DailyProgressCard(),
                        SizedBox(height: 12),
                        HistoryCard(),
                        SizedBox(height: 12),
                        LevelBar(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const ActionButtons(),
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
}
