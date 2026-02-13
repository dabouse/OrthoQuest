import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    // Marquer les récompenses comme vues quand on entre sur l'écran
    if (userState.hasUnseenReward) {
      Future.microtask(
        () => ref.read(userProvider.notifier).setHasUnseenReward(false),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Thèmes & Ambiance')),
      body: AppBackground(
        child: SafeArea(child: _buildThemesGrid(context, ref, userState)),
      ),
    );
  }

  Widget _buildThemesGrid(
    BuildContext context,
    WidgetRef ref,
    UserState state,
  ) {
    final themeNames = AppTheme.themeNames;

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: AppTheme.themes.length,
      itemBuilder: (context, index) {
        final entry = AppTheme.themes.entries.elementAt(index);
        final themeId = entry.key;
        final gradient = entry.value;
        final isUnlocked = state.unlockedThemes.contains(themeId);
        final isActive = state.activeTheme == themeId;

        return GestureDetector(
          onTap: isUnlocked
              ? () => ref.read(userProvider.notifier).setTheme(themeId)
              : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? AppTheme.accentColor : Colors.white24,
                width: isActive ? 3 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.accentColor.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Container(decoration: BoxDecoration(gradient: gradient)),
                  if (!isUnlocked)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Icon(Icons.lock, color: Colors.white, size: 40),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black45,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            themeNames[themeId] ?? themeId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            isUnlocked
                                ? (isActive ? 'Actif' : 'Tap pour utiliser')
                                : 'Niveau ${AppTheme.themeUnlockLevels[themeId] ?? "?"} requis',
                            style: TextStyle(
                              fontSize: 10,
                              color: isUnlocked
                                  ? Colors.greenAccent
                                  : Colors.white38,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
