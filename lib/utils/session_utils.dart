import 'package:flutter/material.dart';
import 'app_theme.dart';

class SessionUtils {
  static const Map<int, Map<String, dynamic>> stickers = {
    0: {
      'icon': Icons.sentiment_very_satisfied,
      'label': 'Super !',
      'color': AppTheme.successColor,
    },
    1: {
      'icon': Icons.sentiment_satisfied,
      'label': 'Bien',
      'color': Color(0xFF00FFCC),
    },
    2: {
      'icon': Icons.sentiment_neutral,
      'label': 'Moyen',
      'color': AppTheme.warningColor,
    },
    3: {
      'icon': Icons.sentiment_dissatisfied,
      'label': 'Douleur',
      'color': Colors.orange,
    },
    4: {
      'icon': Icons.sentiment_very_dissatisfied,
      'label': 'Difficile',
      'color': AppTheme.errorColor,
    },
  };

  static String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours}h$twoDigitMinutes:$twoDigitSeconds";
  }
}
