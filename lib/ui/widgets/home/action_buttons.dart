import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/timer_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/session_utils.dart';
import '../../screens/brushing_screen.dart';
import '../add_manual_session_dialog.dart';

class ActionButtons extends ConsumerWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final isRunning = timerState.isRunning;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Brushing Button
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (isRunning) {
                    _showBrushingWarning(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BrushingScreen(),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    gradient: isRunning
                        ? null
                        : LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isRunning ? Colors.white.withValues(alpha: 0.05) : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRunning ? Colors.white24 : Colors.white,
                      width: isRunning ? 2 : 2.5,
                    ),
                    boxShadow: [
                      if (!isRunning)
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.6),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Icon(
                    Icons.cleaning_services,
                    size: 35,
                    color: isRunning ? Colors.white24 : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "BROSSAGE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                  color: isRunning ? Colors.white24 : Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black,
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                    if (!isRunning)
                      const Shadow(
                        color: AppTheme.primaryColor,
                        blurRadius: 10,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Start/Stop Button (Centered and Larger)
        Expanded(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  glowColor: isRunning
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isRunning
                            ? [AppTheme.errorColor, Colors.black]
                            : [AppTheme.successColor, Colors.green.shade900],
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
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: Icon(
                      isRunning ? Icons.stop : Icons.power_settings_new,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isRunning ? "ARRÊTER" : "DÉMARRER",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.2,
                  color: isRunning
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                  shadows: [
                    const Shadow(
                      color: Colors.black,
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                    Shadow(
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

        // Manual Add Button
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const AddManualSessionDialog(),
                  );
                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Session ajoutée avec succès !'),
                        backgroundColor: AppTheme.successColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.secondaryColor,
                        AppTheme.secondaryColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.6),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_calendar,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "AJOUTER",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                    BoxShadow(color: AppTheme.secondaryColor, blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                          color: Colors.white.withValues(alpha: 0.1),
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
                            color: data['color'] as Color,
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
