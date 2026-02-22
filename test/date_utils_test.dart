import 'package:flutter_test/flutter_test.dart';
import 'package:ortho_quest/utils/date_utils.dart';

void main() {
  group('getReportingDate', () {
    test('minuit (dayEndHour=0) : 23h → même jour', () {
      final date = DateTime(2025, 3, 15, 23, 30);
      final result = OrthoDateUtils.getReportingDate(date, dayEndHour: 0);
      expect(result, DateTime(2025, 3, 15));
    });

    test('minuit (dayEndHour=0) : 0h30 → même jour (pas la veille)', () {
      final date = DateTime(2025, 3, 15, 0, 30);
      final result = OrthoDateUtils.getReportingDate(date, dayEndHour: 0);
      expect(result, DateTime(2025, 3, 15));
    });

    test('5h du matin : 3h → veille', () {
      final date = DateTime(2025, 3, 15, 3, 0);
      final result = OrthoDateUtils.getReportingDate(date, dayEndHour: 5);
      expect(result, DateTime(2025, 3, 14));
    });

    test('5h du matin : 6h → même jour', () {
      final date = DateTime(2025, 3, 15, 6, 0);
      final result = OrthoDateUtils.getReportingDate(date, dayEndHour: 5);
      expect(result, DateTime(2025, 3, 15));
    });

    test('changement de mois : 1er mars 3h avec dayEndHour=5 → 28 fév', () {
      final date = DateTime(2025, 3, 1, 3, 0);
      final result = OrthoDateUtils.getReportingDate(date, dayEndHour: 5);
      expect(result, DateTime(2025, 2, 28));
    });
  });

  group('getDayStart', () {
    test('minuit : retourne minuit du même jour', () {
      final date = DateTime(2025, 3, 15, 14, 0);
      final result = OrthoDateUtils.getDayStart(date, dayEndHour: 0);
      expect(result, DateTime(2025, 3, 15, 0, 0, 0));
    });

    test('5h : 21h → 5h du même jour', () {
      final date = DateTime(2025, 3, 15, 21, 0);
      final result = OrthoDateUtils.getDayStart(date, dayEndHour: 5);
      expect(result, DateTime(2025, 3, 15, 5, 0, 0));
    });

    test('5h : 3h → 5h de la veille', () {
      final date = DateTime(2025, 3, 15, 3, 0);
      final result = OrthoDateUtils.getDayStart(date, dayEndHour: 5);
      expect(result, DateTime(2025, 3, 14, 5, 0, 0));
    });

    test('changement de mois : 1er mars 3h avec dayEndHour=5 → 28 fév 5h', () {
      final date = DateTime(2025, 3, 1, 3, 0);
      final result = OrthoDateUtils.getDayStart(date, dayEndHour: 5);
      expect(result, DateTime(2025, 2, 28, 5, 0, 0));
    });
  });

  group('splitSessionAcrossDays – le cas du fils', () {
    test('21h→7h avec dayEndHour=0 : 3h jour 1 + 7h jour 2', () {
      final start = DateTime(2025, 3, 15, 21, 0); // 21h jour 1
      final end = DateTime(2025, 3, 16, 7, 0);    // 7h jour 2

      final result = OrthoDateUtils.splitSessionAcrossDays(
        start, end, dayEndHour: 0,
      );

      expect(result[DateTime(2025, 3, 15)], 180); // 3h = 180 min
      expect(result[DateTime(2025, 3, 16)], 420); // 7h = 420 min
      expect(result.length, 2);
    });

    test('21h→7h avec dayEndHour=5 : 8h jour 1 + 2h jour 2', () {
      final start = DateTime(2025, 3, 15, 21, 0);
      final end = DateTime(2025, 3, 16, 7, 0);

      final result = OrthoDateUtils.splitSessionAcrossDays(
        start, end, dayEndHour: 5,
      );

      expect(result[DateTime(2025, 3, 15)], 480); // 8h = 480 min
      expect(result[DateTime(2025, 3, 16)], 120); // 2h = 120 min
      expect(result.length, 2);
    });

    test('session dans la même journée : pas de découpe', () {
      final start = DateTime(2025, 3, 15, 9, 0);
      final end = DateTime(2025, 3, 15, 14, 0);

      final result = OrthoDateUtils.splitSessionAcrossDays(
        start, end, dayEndHour: 0,
      );

      expect(result[DateTime(2025, 3, 15)], 300); // 5h
      expect(result.length, 1);
    });

    test('session très longue traversant 3 jours', () {
      final start = DateTime(2025, 3, 15, 20, 0); // 20h jour 1
      final end = DateTime(2025, 3, 17, 10, 0);   // 10h jour 3

      final result = OrthoDateUtils.splitSessionAcrossDays(
        start, end, dayEndHour: 0,
      );

      expect(result[DateTime(2025, 3, 15)], 240);  // 4h (20h→00h)
      expect(result[DateTime(2025, 3, 16)], 1440); // 24h (00h→00h)
      expect(result[DateTime(2025, 3, 17)], 600);  // 10h (00h→10h)
      expect(result.length, 3);
    });
  });

  group('clipSessionToDay', () {
    test('session 21h→7h, clipper au jour 2 (dayEndHour=0) → 7h', () {
      final start = DateTime(2025, 3, 15, 21, 0);
      final end = DateTime(2025, 3, 16, 7, 0);

      final ms = OrthoDateUtils.clipSessionToDay(
        start, end,
        targetDate: DateTime(2025, 3, 16),
        dayEndHour: 0,
      );

      expect(ms, 7 * 3600 * 1000); // 7h en ms
    });

    test('session 21h→7h, clipper au jour 1 (dayEndHour=0) → 3h', () {
      final start = DateTime(2025, 3, 15, 21, 0);
      final end = DateTime(2025, 3, 16, 7, 0);

      final ms = OrthoDateUtils.clipSessionToDay(
        start, end,
        targetDate: DateTime(2025, 3, 15),
        dayEndHour: 0,
      );

      expect(ms, 3 * 3600 * 1000); // 3h en ms
    });

    test('session hors fenêtre → 0', () {
      final start = DateTime(2025, 3, 15, 9, 0);
      final end = DateTime(2025, 3, 15, 14, 0);

      final ms = OrthoDateUtils.clipSessionToDay(
        start, end,
        targetDate: DateTime(2025, 3, 16),
        dayEndHour: 0,
      );

      expect(ms, 0);
    });

    test('session entièrement dans la fenêtre → durée complète', () {
      final start = DateTime(2025, 3, 15, 9, 0);
      final end = DateTime(2025, 3, 15, 14, 0);

      final ms = OrthoDateUtils.clipSessionToDay(
        start, end,
        targetDate: DateTime(2025, 3, 15),
        dayEndHour: 0,
      );

      expect(ms, 5 * 3600 * 1000); // 5h en ms
    });
  });
}
