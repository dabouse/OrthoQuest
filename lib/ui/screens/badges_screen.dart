import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/badge.dart' as model;
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';
import '../widgets/vibrant_card.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final unlockedIds = userState.unlockedBadges;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Mes Badges"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showBadgesInfo(context),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: model.appBadges.length,
            itemBuilder: (context, index) {
              final badge = model.appBadges[index];
              final isUnlocked = unlockedIds.contains(badge.id);

              return _buildBadgeItem(badge, isUnlocked);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeItem(model.Badge badge, bool isUnlocked) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.6,
      child: VibrantCard(
        padding: const EdgeInsets.all(8),
        color: isUnlocked
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? badge.color.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? badge.icon : Icons.lock,
                size: 28,
                color: isUnlocked ? badge.color : Colors.white38,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isUnlocked ? Colors.white : Colors.white38,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgesInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Comment débloquer ?"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBadgeInfoRow(
                Icons.directions_walk,
                "Premiers Pas",
                "Termine ta 1ère session.",
              ),
              _buildBadgeInfoRow(
                Icons.nights_stay,
                "Oiseau de Nuit",
                "5 sessions avec la Lune.",
              ),
              _buildBadgeInfoRow(
                Icons.local_fire_department,
                "Dents d'Acier",
                "Série de 7 jours (13h+).",
              ),
              _buildBadgeInfoRow(
                Icons.clean_hands,
                "Pro de l'Hygiène",
                "10 sessions de brossage.",
              ),
              _buildBadgeInfoRow(
                Icons.timer,
                "Marathonien",
                "Porte l'appareil 16h+ par jour.",
              ),
            ],
          ),
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

  Widget _buildBadgeInfoRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.secondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
