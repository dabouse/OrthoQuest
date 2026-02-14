/// Utilitaires pour la manipulation des dates spécifiques à OrthoQuest.
///
/// La limite de journée [dayEndHour] (par défaut 5 = 5h du matin) est configurable
/// via les paramètres de l'application.
class OrthoDateUtils {
  /// Retourne la date de rapport (journée débutant à [dayEndHour]h du matin).
  ///
  /// Si l'heure est avant [dayEndHour]h, la date retournée est celle de la veille.
  /// [dayEndHour] : heure à partir de laquelle une nouvelle journée commence (0-23).
  static DateTime getReportingDate(DateTime date, {int dayEndHour = 5}) {
    final hour = dayEndHour.clamp(0, 23);
    if (date.hour < hour) {
      final prev = date.subtract(const Duration(days: 1));
      return DateTime(prev.year, prev.month, prev.day);
    }
    return DateTime(date.year, date.month, date.day);
  }

  /// Retourne le début de la "journée OrthoQuest" ([dayEndHour]h du matin).
  ///
  /// Utilise [Duration] pour éviter les dates invalides (ex. jour 0).
  /// [dayEndHour] : heure à partir de laquelle une nouvelle journée commence (0-23).
  static DateTime getDayStart(DateTime date, {int dayEndHour = 5}) {
    final hour = dayEndHour.clamp(0, 23);
    if (date.hour < hour) {
      final prevMidnight = DateTime(date.year, date.month, date.day);
      final prevDay = prevMidnight.subtract(const Duration(days: 1));
      return DateTime(prevDay.year, prevDay.month, prevDay.day, hour, 0, 0);
    }
    return DateTime(date.year, date.month, date.day, hour, 0, 0);
  }
}
