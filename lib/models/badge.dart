import 'package:flutter/material.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<Badge> appBadges = [
  Badge(
    id: 'first_steps',
    name: 'Premiers Pas',
    description: 'Complète ta première session.',
    icon: Icons.directions_walk,
    color: Colors.blue,
  ),
  Badge(
    id: 'night_owl',
    name: 'Oiseau de Nuit',
    description: 'Enregistre 5 sessions de nuit.',
    icon: Icons.nights_stay,
    color: Colors.indigo,
  ),
  Badge(
    id: 'steel_teeth',
    name: 'Dents d\'Acier',
    description: 'Atteins une série de 7 jours (13h+).',
    icon: Icons.shield,
    color: Colors.grey,
  ),
  Badge(
    id: 'hygiene_pro',
    name: 'Pro de l\'Hygiène',
    description: 'Gagne de l\'XP en te brossant les dents 10 fois.',
    icon: Icons.clean_hands,
    color: Colors.teal,
  ),
  Badge(
    id: 'marathon',
    name: 'Marathonien',
    description: 'Porte ton appareil plus de 16h en un jour.',
    icon: Icons.timer,
    color: Colors.orange,
  ),
];
