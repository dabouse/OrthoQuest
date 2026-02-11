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
        color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? badge.color.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? badge.icon : Icons.lock,
                size: 28,
                color: isUnlocked ? badge.color : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isUnlocked ? Colors.black87 : Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
