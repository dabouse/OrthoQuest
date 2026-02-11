/// Utilitaires pour la manipulation des dates spécifiques à OrthoQuest.
class OrthoDateUtils {
  /// Retourne la date de rapport (journée commençant à 5h du matin).
  ///
  /// Si l'heure est avant 5h, la date retournée est celle de la veille.
  static DateTime getReportingDate(DateTime date) {
    if (date.hour < 5) {
      final prev = date.subtract(const Duration(days: 1));
      return DateTime(prev.year, prev.month, prev.day);
    }
    return DateTime(date.year, date.month, date.day);
  }

  /// Retourne le début de la "journée OrthoQuest" (5h du matin).
  static DateTime getDayStart(DateTime date) {
    if (date.hour < 5) {
      return DateTime(date.year, date.month, date.day - 1, 5);
    }
    return DateTime(date.year, date.month, date.day, 5);
  }
}
