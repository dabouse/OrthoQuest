/// Valeurs par défaut de l'application, centralisées en un seul endroit.
///
/// Modifier une constante ici la change partout dans l'application
/// (base de données, providers, écrans de paramètres, etc.).
class AppDefaults {
  AppDefaults._();

  /// Heure de changement de journée (0 = minuit, 5 = 5h du matin, etc.).
  static const int dayEndHour = 0;

  /// Objectif quotidien de port en heures.
  static const int dailyGoalHours = 13;

  /// Durée du brossage de dents en secondes (300 = 5 minutes).
  static const int brushingDurationSeconds = 300;
}
