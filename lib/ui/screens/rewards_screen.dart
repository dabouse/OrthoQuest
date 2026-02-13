import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';
import '../widgets/vibrant_card.dart';

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
      appBar: AppBar(title: const Text('Personnalisation')),
      body: AppBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildAppearanceSection(context, ref, userState),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.palette, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Thèmes Débloqués",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: _buildThemesSliverGrid(context, ref, userState),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    WidgetRef ref,
    UserState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Transparence
          const Row(
            children: [
              Icon(Icons.opacity, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                "Transparence du plateau",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          VibrantCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.blur_on, color: AppTheme.primaryColor),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.primaryColor.withValues(
                        alpha: 0.2,
                      ),
                      thumbColor: AppTheme.primaryColor,
                    ),
                    child: Slider(
                      value: state.sectionOpacity,
                      min: 0.0,
                      max: 0.5,
                      divisions: 10,
                      label: "${(state.sectionOpacity * 100).toInt()}%",
                      onChanged: (value) {
                        ref
                            .read(userProvider.notifier)
                            .setSectionOpacity(value);
                      },
                    ),
                  ),
                ),
                Text(
                  "${(state.sectionOpacity * 100).toInt()}%",
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Flou
          const Row(
            children: [
              Icon(Icons.blur_linear, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                "Intensité du flou",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          VibrantCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.lens_blur, color: AppTheme.primaryColor),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.primaryColor.withValues(
                        alpha: 0.2,
                      ),
                      thumbColor: AppTheme.primaryColor,
                    ),
                    child: Slider(
                      value: state.sectionBlur,
                      min: 0.0,
                      max: 20.0,
                      divisions: 20,
                      label: "${state.sectionBlur.toInt()}",
                      onChanged: (value) {
                        ref.read(userProvider.notifier).setSectionBlur(value);
                      },
                    ),
                  ),
                ),
                Text(
                  "${state.sectionBlur.toInt()}",
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemesSliverGrid(
    BuildContext context,
    WidgetRef ref,
    UserState state,
  ) {
    final themeNames = AppTheme.themeNames;

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
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
                  // Vignette: Image if exists, otherwise Gradient
                  Positioned.fill(
                    child: AppTheme.themeImagePaths[themeId] != null
                        ? Image.asset(
                            AppTheme.themeImagePaths[themeId]!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(gradient: gradient),
                          ),
                  ),
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
                                : 'Niv. ${AppTheme.themeUnlockLevels[themeId]} req.',
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
      }, childCount: AppTheme.themes.length),
    );
  }
}
