import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/timer_provider.dart';
import 'services/notification_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // Initialiser le service de notifications
  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  runApp(const ProviderScope(child: OrthoQuestApp()));
}

/// Widget principal de l'application qui gère le cycle de vie.
class OrthoQuestApp extends ConsumerStatefulWidget {
  const OrthoQuestApp({super.key});

  @override
  ConsumerState<OrthoQuestApp> createState() => _OrthoQuestAppState();
}

class _OrthoQuestAppState extends ConsumerState<OrthoQuestApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Observer le cycle de vie de l'application
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Retirer l'observer lors de la destruction du widget
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Récupérer le notifier du timer
    final timerNotifier = ref.read(timerProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
        // L'application passe en arrière-plan
        timerNotifier.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        // L'application revient au premier plan
        timerNotifier.onAppResumed();
        break;
      default:
        break;
    }
  }

  Future<bool> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrthoQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: FutureBuilder<bool>(
        future: _checkFirstLaunch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: const BoxDecoration(color: Colors.black),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryColor.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 300,
                        height: 300,
                      ),
                    ),
                    const SizedBox(height: 50),
                    const CircularProgressIndicator(
                      color: AppTheme.secondaryColor,
                    ),
                  ],
                ),
              ),
            );
          }

          final hasCompletedOnboarding = snapshot.data ?? false;
          return hasCompletedOnboarding
              ? const HomeScreen()
              : const OnboardingScreen();
        },
      ),
    );
  }
}
