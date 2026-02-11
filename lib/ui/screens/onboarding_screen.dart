import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isReplay;
  const OnboardingScreen({super.key, this.isReplay = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.emoji_emotions,
      iconColor: AppTheme.primaryColor,
      title: "Bienvenue sur OrthoQuest !",
      description:
          "Ton compagnon pour suivre le port de ton appareil dentaire et rendre le traitement plus amusant.",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      ),
    ),
    OnboardingPage(
      icon: Icons.timer,
      iconColor: AppTheme.secondaryColor,
      title: "Suivi du Temps",
      description:
          "Enregistre le temps de port de ton appareil chaque jour. L'objectif est de porter l'appareil 12 à 13 heures par jour.",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A2E), Color(0xFF240046)],
      ),
    ),
    OnboardingPage(
      icon: Icons.military_tech,
      iconColor: AppTheme.warningColor,
      title: "Gagne des Badges",
      description:
          "Débloque des badges en respectant tes objectifs et en faisant preuve de régularité. Plus tu es assidu, plus tu gagnes de récompenses !",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A2E), Color(0xFF3E2723)],
      ),
    ),
    OnboardingPage(
      icon: Icons.cleaning_services,
      iconColor: AppTheme.successColor,
      title: "Brossage des Dents",
      description:
          "N'oublie pas de te brosser les dents ! Utilise le minuteur de brossage pour respecter les 2 minutes recommandées.",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A2E), Color(0xFF004D40)],
      ),
    ),
    OnboardingPage(
      icon: Icons.stars,
      iconColor: AppTheme.primaryColor,
      title: "Deviens un Héros !",
      description:
          "Gagne 10 XP par heure de port et 50 XP par brossage. Monte de niveau pour devenir une légende et débloquer des badges !",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A2E), Color(0xFF1E3C72)],
      ),
    ),
    OnboardingPage(
      icon: Icons.rocket_launch,
      iconColor: AppTheme.accentColor,
      title: "C'est Parti !",
      description:
          "Tu es prêt à commencer ton aventure OrthoQuest. Continue comme ça et tu auras bientôt un sourire éclatant !",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A2E), Color(0xFF311B92)],
      ),
    ),
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    if (widget.isReplay) {
      Navigator.of(context).pop();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _pages[_currentPage].gradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      "Passer",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildIndicator(index == _currentPage),
                  ),
                ),
              ),

              // Next/Start button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].iconColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                      shadowColor: _pages[_currentPage].iconColor.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1
                              ? "Commencer"
                              : "Suivant",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == _pages.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: page.iconColor.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(page.icon, size: 70, color: page.iconColor),
            ),
          ),

          const SizedBox(height: 50),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? _pages[_currentPage].iconColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Gradient gradient;

  OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
