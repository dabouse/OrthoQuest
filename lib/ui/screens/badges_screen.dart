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
      appBar: AppBar(title: const Text("Mes Badges"), centerTitle: true),

      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: model.appBadges.length,
                    itemBuilder: (context, index) {
                      final badge = model.appBadges[index];
                      final isUnlocked = unlockedIds.contains(badge.id);

                      return _buildBadgeItem(context, badge, isUnlocked);
                    },
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () => _showBadgesInfo(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.warningColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 18,
                            color: AppTheme.warningColor,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Comment débloquer les badges ?",
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeItem(
    BuildContext context,
    model.Badge badge,
    bool isUnlocked,
  ) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badge, isUnlocked),
      child: Opacity(
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
      ),
    );
  }

  void _showBadgeDetail(
    BuildContext context,
    model.Badge badge,
    bool isUnlocked,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isUnlocked
                ? badge.color.withValues(alpha: 0.8)
                : Colors.white10,
            width: 2,
          ),
        ),
        title: Text(
          badge.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? badge.color.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  if (isUnlocked)
                    BoxShadow(
                      color: badge.color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Icon(
                isUnlocked ? badge.icon : Icons.lock_outline,
                size: 60,
                color: isUnlocked ? badge.color : Colors.white24,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isUnlocked ? "Badge débloqué !" : "Objectif à atteindre :",
              style: TextStyle(
                fontSize: 14,
                color: isUnlocked ? AppTheme.successColor : Colors.white54,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                badge.description,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUnlocked ? badge.color : Colors.white10,
                foregroundColor: isUnlocked
                    ? (badge.color == AppTheme.primaryColor ||
                              badge.color == AppTheme.warningColor ||
                              badge.color == AppTheme.successColor
                          ? Colors.black
                          : Colors.white)
                    : Colors.white,
              ),
              child: const Text("Génial !"),
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgesInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        title: const Text(
          "Tous les Badges",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Collectionne-les tous en relevant ces défis !",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 20),
              ...model.appBadges.map((badge) => _buildBadgeInfoRow(badge)),
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
              child: const Text("Compris !"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeInfoRow(model.Badge badge) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badge.color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(badge.icon, size: 20, color: badge.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  badge.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
