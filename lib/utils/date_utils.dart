import 'app_defaults.dart';

/// Utilitaires pour la manipulation des dates spécifiques à OrthoQuest.
///
/// La limite de journée [dayEndHour] est configurable via les paramètres
/// de l'application. La valeur par défaut est définie dans [AppDefaults].
class OrthoDateUtils {
  /// Retourne la date de rapport (journée débutant à [dayEndHour]h).
  ///
  /// Si l'heure est avant [dayEndHour]h, la date retournée est celle de la veille.
  /// [dayEndHour] : heure à partir de laquelle une nouvelle journée commence (0-23).
  static DateTime getReportingDate(DateTime date, {int dayEndHour = AppDefaults.dayEndHour}) {
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
  static DateTime getDayStart(DateTime date, {int dayEndHour = AppDefaults.dayEndHour}) {
    final hour = dayEndHour.clamp(0, 23);
    if (date.hour < hour) {
      final prevMidnight = DateTime(date.year, date.month, date.day);
      final prevDay = prevMidnight.subtract(const Duration(days: 1));
      return DateTime(prevDay.year, prevDay.month, prevDay.day, hour, 0, 0);
    }
    return DateTime(date.year, date.month, date.day, hour, 0, 0);
  }

  /// Retourne la fin de la "journée OrthoQuest" = début + 24h.
  static DateTime getDayEnd(DateTime date, {int dayEndHour = AppDefaults.dayEndHour}) {
    return getDayStart(date, dayEndHour: dayEndHour)
        .add(const Duration(days: 1));
  }

  /// Découpe la durée d'une session entre les jours qu'elle traverse.
  ///
  /// Retourne une map {reportingDate → durée en minutes} pour chaque
  /// jour couvert par l'intervalle [start, end].
  static Map<DateTime, int> splitSessionAcrossDays(
    DateTime start,
    DateTime end, {
    int dayEndHour = AppDefaults.dayEndHour,
  }) {
    final result = <DateTime, int>{};
    DateTime segStart = start;

    while (segStart.isBefore(end)) {
      final reportDate = getReportingDate(segStart, dayEndHour: dayEndHour);
      final dayBoundary = getDayEnd(segStart, dayEndHour: dayEndHour);
      final segEnd = end.isBefore(dayBoundary) ? end : dayBoundary;
      final minutes = segEnd.difference(segStart).inMinutes;
      if (minutes > 0) {
        result[reportDate] = (result[reportDate] ?? 0) + minutes;
      }
      segStart = segEnd;
    }

    return result;
  }

  /// Retourne la durée (ms) d'une session clippée à la fenêtre d'un jour donné.
  ///
  /// [targetDate] est la date de reporting (minuit). La fenêtre couvre
  /// [targetDate + dayEndHour] → [targetDate + dayEndHour + 24h].
  static int clipSessionToDay(
    DateTime start,
    DateTime end, {
    required DateTime targetDate,
    int dayEndHour = AppDefaults.dayEndHour,
  }) {
    final hour = dayEndHour.clamp(0, 23);
    final windowStart = DateTime(targetDate.year, targetDate.month, targetDate.day, hour);
    final windowEnd = windowStart.add(const Duration(days: 1));

    final effectiveStart = start.isBefore(windowStart) ? windowStart : start;
    final effectiveEnd = end.isAfter(windowEnd) ? windowEnd : end;

    if (effectiveEnd.isAfter(effectiveStart)) {
      return effectiveEnd.difference(effectiveStart).inMilliseconds;
    }
    return 0;
  }
}
