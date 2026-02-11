import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_service.dart';
import '../../providers/timer_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';
import '../widgets/vibrant_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _dayEndHour = 5;
  int _brushingDuration = 120;
  int _dailyGoal = 13;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dayEnd = await DatabaseService().getSetting('day_end_hour');
    final brushing = await DatabaseService().getSetting('brushing_duration');
    final goal = await DatabaseService().getSetting('daily_goal');

    setState(() {
      _dayEndHour = int.tryParse(dayEnd ?? '5') ?? 5;
      _brushingDuration = int.tryParse(brushing ?? '120') ?? 120;
      _dailyGoal = int.tryParse(goal ?? '13') ?? 13;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, int newValue) async {
    await DatabaseService().updateSetting(key, newValue.toString());
    setState(() {
      if (key == 'day_end_hour') _dayEndHour = newValue;
      if (key == 'brushing_duration') _brushingDuration = newValue;
      if (key == 'daily_goal') _dailyGoal = newValue;
    });

    // Notify TimerProvider
    if (key == 'daily_goal') {
      ref.read(timerProvider.notifier).refreshSettings();
      ref.read(userProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("Paramètres")),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    VibrantCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Configuration",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // DAY END HOUR
                          _buildSettingTile(
                            "Heure de fin de journée",
                            "Les sessions après cette heure compteront pour le jour suivant. Actuellement : ${_dayEndHour}h00",
                            DropdownButton<int>(
                              value: _dayEndHour,
                              underline: const SizedBox(),
                              items: List.generate(24, (index) {
                                return DropdownMenuItem(
                                  value: index,
                                  child: Text("${index}h00"),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) {
                                  _updateSetting('day_end_hour', val);
                                }
                              },
                            ),
                          ),
                          const Divider(height: 32),

                          // BRUSHING DURATION
                          _buildSettingTile(
                            "Durée du brossage",
                            "Temps à respecter pour le brossage des dents. Actuellement : $_brushingDuration sec",
                            DropdownButton<int>(
                              value: _brushingDuration,
                              underline: const SizedBox(),
                              items: [60, 120, 180, 240, 300].map((val) {
                                return DropdownMenuItem(
                                  value: val,
                                  child: Text("${val ~/ 60} min"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  _updateSetting('brushing_duration', val);
                                }
                              },
                            ),
                          ),
                          const Divider(height: 32),

                          // DAILY GOAL
                          _buildSettingTile(
                            "Objectif quotidien",
                            "Nombre d'heures à porter l'appareil. Actuellement : $_dailyGoal h\nRecommandé : 12h à 13h / jour",
                            DropdownButton<int>(
                              value: _dailyGoal,
                              underline: const SizedBox(),
                              items: List.generate(24, (index) => index + 1)
                                  .map((val) {
                                    return DropdownMenuItem(
                                      value: val,
                                      child: Text("$val h"),
                                    );
                                  })
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  _updateSetting('daily_goal', val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    VibrantCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "À propos",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Version"),
                            subtitle: const Text("1.0.0"),
                            leading: Icon(
                              Icons.info_outline,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Développé pour"),
                            subtitle: const Text("Damien & OrthoQuest"),
                            leading: Icon(
                              Icons.favorite_border,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, Widget trailing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}
