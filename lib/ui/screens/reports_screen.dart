import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import 'pdf_preview_screen.dart';
import '../../providers/timer_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/session.dart';
import '../../utils/session_utils.dart';
import '../../utils/date_utils.dart';
import '../widgets/vibrant_card.dart';
import '../widgets/session_actions_sheet.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

enum ReportViewMode { week, month }

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  Map<DateTime, int> _allStats = {};
  List<Session> _allSessions = [];
  bool _isLoading = true;
  ReportViewMode _viewMode = ReportViewMode.week;
  DateTime _focusDate = DateTime.now();
  DateTime? _selectedDate; // Pour afficher le détail d'un jour spécifique
  int? _selectedSessionId; // Pour mettre en surbrillance une session spécifique

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DatabaseService().getDailySummaries();
      final sessions = await DatabaseService().getSessions();
      if (mounted) {
        setState(() {
          _allStats = stats;
          _allSessions = sessions;
          _isLoading = false;
          _selectedDate = DateTime(
            _focusDate.year,
            _focusDate.month,
            _focusDate.day,
          );
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement statistiques : $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime _getStartOfPeriod() {
    if (_viewMode == ReportViewMode.week) {
      // Start of week (Monday)
      int daysToSubtract = _focusDate.weekday - 1;
      return DateTime(
        _focusDate.year,
        _focusDate.month,
        _focusDate.day,
      ).subtract(Duration(days: daysToSubtract));
    } else {
      // Start of month
      return DateTime(_focusDate.year, _focusDate.month, 1);
    }
  }

  int _getDaysInPeriod() {
    if (_viewMode == ReportViewMode.week) return 7;
    return DateTime(_focusDate.year, _focusDate.month + 1, 0).day;
  }

  void _navigate(int delta) {
    setState(() {
      if (_viewMode == ReportViewMode.week) {
        _focusDate = _focusDate.add(Duration(days: 7 * delta));
      } else {
        _focusDate = DateTime(_focusDate.year, _focusDate.month + delta, 1);
      }
      // Réinitialiser la sélection lors du changement de période
      _selectedDate = null;
      _selectedSessionId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final startOfPeriod = _getStartOfPeriod();
    final daysInPeriod = _getDaysInPeriod();

    // Filter stats for current period
    final periodStats = <DateTime, int>{};
    int totalMinutes = 0;

    for (int i = 0; i < daysInPeriod; i++) {
      final date = startOfPeriod.add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final mins = _allStats[normalizedDate] ?? 0;
      periodStats[normalizedDate] = mins;
      totalMinutes += mins;
    }

    final timerState = ref.watch(timerProvider);
    final dailyGoal = timerState.dailyGoal;
    final targetMins = dailyGoal * 60;

    int maxMinutes = periodStats.values.isEmpty
        ? 0
        : periodStats.values.reduce(math.max);

    // Dynamic scale: Max between data and goal, plus 1h30 to avoid clipping labels
    double chartMaxY =
        math.max(targetMins.toDouble(), maxMinutes.toDouble()) + 90;

    double avgMinutes = daysInPeriod == 0 ? 0 : totalMinutes / daysInPeriod;

    String periodLabel = "";
    if (_viewMode == ReportViewMode.week) {
      final endOfWeek = startOfPeriod.add(const Duration(days: 6));
      periodLabel =
          "Semaine du ${DateFormat('dd/MM').format(startOfPeriod)} au ${DateFormat('dd/MM').format(endOfWeek)}";
    } else {
      periodLabel = DateFormat('MMMM yyyy', 'fr_FR').format(startOfPeriod);
      // Capitalize first letter
      periodLabel = periodLabel[0].toUpperCase() + periodLabel.substring(1);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Statistiques",
          style: (Theme.of(context).appBarTheme.titleTextStyle ??
                  const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
              .copyWith(shadows: AppTheme.textShadows),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfPreviewScreen(
                    stats: periodStats,
                    periodLabel: periodLabel,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // View Mode Selector
                      SegmentedButton<ReportViewMode>(
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppTheme.primaryColor.withValues(
                                    alpha: 0.7,
                                  ); // Encore plus opaque
                                }
                                return Colors.white.withValues(
                                  alpha: 0.4,
                                ); // Encore plus opaque
                              }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppTheme.primaryColor;
                                }
                                return Colors.white;
                              }),
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(
                              shadows: AppTheme.textShadows,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          iconColor: WidgetStateProperty.all(Colors.white),
                          side: WidgetStateProperty.all(
                            BorderSide(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.8,
                              ),
                              width: 1.5,
                            ),
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          elevation: WidgetStateProperty.all(
                            5,
                          ), // Ajout d'une petite élévation/ombre
                          shadowColor: WidgetStateProperty.all(
                            Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: ReportViewMode.week,
                            label: const Text("Semaine"),
                            icon: const Icon(
                              Icons.date_range,
                              shadows: AppTheme.textShadows,
                            ),
                          ),
                          ButtonSegment(
                            value: ReportViewMode.month,
                            label: Text("Mois"),
                            icon: Icon(
                              Icons.calendar_month,
                              shadows: AppTheme.textShadows,
                            ),
                          ),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _viewMode = newSelection.first;
                            _selectedDate = null;
                            _selectedSessionId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                              ),
                              onPressed: () => _navigate(-1),
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  periodLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                    shadows: AppTheme.textShadows,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                              ),
                              onPressed: () => _navigate(1),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Main Stats block
                      Expanded(
                        child: VibrantCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Summary Cards inside the main card
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryCard(
                                      "Moyenne",
                                      "${(avgMinutes / 60).toStringAsFixed(1)}h",
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      _viewMode == ReportViewMode.week
                                          ? "7 jours"
                                          : "Mois",
                                      "${(totalMinutes / 60).toStringAsFixed(1)}h",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Chart
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.55,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                          spreadRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: InteractiveViewer(
                                      panEnabled: true,
                                      scaleEnabled: true,
                                      minScale: 1.0,
                                      maxScale: 5.0,
                                      child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: chartMaxY,
                                      extraLinesData: ExtraLinesData(
                                        horizontalLines: [
                                          HorizontalLine(
                                            y: targetMins.toDouble(),
                                            color: Colors.black,
                                            strokeWidth: 1.5,
                                            label: HorizontalLineLabel(
                                              show: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        handleBuiltInTouches: false,
                                        touchCallback:
                                            (FlTouchEvent event, barResponse) {
                                              if (event is! FlTapUpEvent ||
                                                  barResponse == null ||
                                                  barResponse.spot == null) {
                                                return;
                                              }
                                              setState(() {
                                                final index = barResponse
                                                    .spot!
                                                    .touchedBarGroupIndex;

                                                final date = startOfPeriod.add(
                                                  Duration(days: index),
                                                );

                                                final targetDate = DateTime(
                                                  date.year,
                                                  date.month,
                                                  date.day,
                                                );

                                                if (_selectedDate != null &&
                                                    DateUtils.isSameDay(
                                                      _selectedDate!,
                                                      targetDate,
                                                    )) {
                                                  _selectedDate = null;
                                                  _selectedSessionId = null;
                                                } else {
                                                  _selectedDate = targetDate;
                                                  _selectedSessionId = null;
                                                }
                                              });
                                            },
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget:
                                                (double value, TitleMeta meta) {
                                                  final index = value.toInt();
                                                  if (index < 0 ||
                                                      index >= daysInPeriod) {
                                                    return const SizedBox.shrink();
                                                  }

                                                  final date = startOfPeriod
                                                      .add(
                                                        Duration(days: index),
                                                      );
                                                  final today = DateTime.now();
                                                  final isToday =
                                                      DateUtils.isSameDay(
                                                        date,
                                                        today,
                                                      );
                                                  if (_viewMode ==
                                                      ReportViewMode.month) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 12.0,
                                                          ),
                                                      child: Transform.rotate(
                                                        angle: -1.5708,
                                                        child: Text(
                                                          "${date.day}",
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            color: isToday
                                                                ? AppTheme
                                                                      .primaryColor
                                                                : Colors.white,
                                                            shadows: AppTheme
                                                                .textShadows,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                        ),
                                                    child: Text(
                                                      DateFormat(
                                                        'E',
                                                        'fr_FR',
                                                      ).format(date),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: isToday
                                                            ? AppTheme
                                                                  .primaryColor
                                                            : Colors.white,
                                                        shadows: AppTheme
                                                            .textShadows,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 45,
                                            interval: chartMaxY > 600
                                                ? 120
                                                : 60,
                                            getTitlesWidget: (value, meta) {
                                              if (value == meta.max &&
                                                  value %
                                                          (chartMaxY > 600
                                                              ? 120
                                                              : 60) !=
                                                      0) {
                                                return const SizedBox.shrink();
                                              }

                                              if (value %
                                                      (chartMaxY > 600
                                                          ? 120
                                                          : 60) ==
                                                  0) {
                                                return Text(
                                                  '${(value / 60).toInt()}h',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                    shadows:
                                                        AppTheme.textShadows,
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval: chartMaxY > 600
                                            ? 120
                                            : 60,
                                        getDrawingHorizontalLine: (value) =>
                                            FlLine(
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                              strokeWidth: 1,
                                            ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            width: 1,
                                          ),
                                          left: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      barGroups: List.generate(daysInPeriod, (
                                        index,
                                      ) {
                                        final date = startOfPeriod.add(
                                          Duration(days: index),
                                        );
                                        final normalizedDate = DateTime(
                                          date.year,
                                          date.month,
                                          date.day,
                                        );

                                        final dayEndHour = timerState.dayEndHour;
                                        final daySessions = _allSessions.where((
                                          s,
                                        ) {
                                          if (s.endTime == null) {
                                            return false;
                                          }
                                          return DateUtils.isSameDay(
                                            OrthoDateUtils.getReportingDate(
                                              s.startTime,
                                              dayEndHour: dayEndHour,
                                            ),
                                            normalizedDate,
                                          );
                                        }).toList();
                                        daySessions.sort(
                                          (a, b) => a.startTime.compareTo(
                                            b.startTime,
                                          ),
                                        );

                                        List<BarChartRodStackItem> stackItems =
                                            [];
                                        double currentY = 0;

                                        for (var s in daySessions) {
                                          final dur = s.durationInMinutes
                                              .toDouble();
                                          final stickerId = s.stickerId;
                                          final isSelected =
                                              s.id == _selectedSessionId;
                                          Color color =
                                              (stickerId != null &&
                                                  SessionUtils.stickers
                                                      .containsKey(stickerId))
                                              ? SessionUtils
                                                        .stickers[stickerId]!['color']
                                                    as Color
                                              : AppTheme.primaryColor
                                                    .withValues(alpha: 0.5);

                                          if (_selectedSessionId != null &&
                                              !isSelected) {
                                            color = color.withValues(
                                              alpha: 0.2,
                                            );
                                          }

                                          stackItems.add(
                                            BarChartRodStackItem(
                                              currentY,
                                              currentY + dur,
                                              color,
                                            ),
                                          );
                                          currentY += dur;
                                        }

                                        final today = DateTime.now();
                                        final isToday = DateUtils.isSameDay(
                                          normalizedDate,
                                          today,
                                        );

                                        final isSelectedDay =
                                            _selectedDate != null &&
                                            DateUtils.isSameDay(
                                              normalizedDate,
                                              _selectedDate!,
                                            );

                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: currentY,
                                              rodStackItems: stackItems,
                                              width:
                                                  _viewMode ==
                                                      ReportViewMode.week
                                                  ? 22
                                                  : 8,
                                              backDrawRodData:
                                                  BackgroundBarChartRodData(
                                                    show: true,
                                                    toY: targetMins.toDouble(),
                                                    color: AppTheme
                                                        .secondaryColor
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: isSelectedDay
                                                  ? const BorderSide(
                                                      color: Colors.white,
                                                      width: 2,
                                                    )
                                                  : (isToday
                                                        ? const BorderSide(
                                                            color: Colors.blue,
                                                            width: 2,
                                                          )
                                                        : BorderSide.none),
                                              color: isToday
                                                  ? AppTheme.primaryColor
                                                        .withValues(alpha: 0.1)
                                                  : Colors.white.withValues(
                                                      alpha: 0.05,
                                                    ),
                                            ),
                                          ],
                                          showingTooltipIndicators: const [],
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                              // Stickers Timeline inside the card
                              _buildStickersTimeline(
                                startOfPeriod,
                                daysInPeriod,
                                timerState.dayEndHour,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStickersTimeline(
    DateTime startOfPeriod,
    int daysInPeriod,
    int dayEndHour,
  ) {
    final endOfPeriod = startOfPeriod.add(Duration(days: daysInPeriod));

    final filteredSessions = _allSessions.where((s) {
      if (s.endTime == null) return false;
      final sessionDate = OrthoDateUtils.getReportingDate(
        s.startTime,
        dayEndHour: dayEndHour,
      );

      // Si un jour est sélectionné, on filtre. Sinon on montre toute la période.
      if (_selectedDate != null) {
        return DateUtils.isSameDay(sessionDate, _selectedDate!);
      }

      return (sessionDate.isAtSameMomentAs(startOfPeriod) ||
              sessionDate.isAfter(startOfPeriod)) &&
          sessionDate.isBefore(endOfPeriod);
    }).toList();

    filteredSessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (filteredSessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          _selectedDate != null
              ? "Aucun sticker pour ce jour"
              : "Aucun sticker sur cette période",
          style: const TextStyle(
            color: Colors.white54,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDate != null
                          ? "Journée du ${DateFormat('dd MMMM', 'fr_FR').format(_selectedDate!)}"
                          : "Toutes les sessions",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: AppTheme.textShadows,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedDate != null)
                      Text(
                        "${(_allStats[_selectedDate!] ?? 0) ~/ 60}h ${(_allStats[_selectedDate!] ?? 0) % 60}min au total",
                        style: TextStyle(
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: AppTheme.textShadows,
                        ),
                      ),
                  ],
                ),
              ),
              if (_selectedDate != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                      _selectedSessionId = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.3,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filteredSessions.length,
            itemBuilder: (context, index) {
              final session = filteredSessions[index];
              final stickerId = session.stickerId;
              if (stickerId == null ||
                  !SessionUtils.stickers.containsKey(stickerId)) {
                return const SizedBox.shrink();
              }
              final data = SessionUtils.stickers[stickerId]!;

              final isSelected = session.id == _selectedSessionId;

              return GestureDetector(
                onTap: () {
                    setState(() {
                      if (_selectedSessionId == session.id) {
                        _selectedSessionId = null;
                        _selectedDate = null;
                      } else {
                        _selectedSessionId = session.id;
                        final dayEnd = ref.read(timerProvider).dayEndHour;
                        _selectedDate = OrthoDateUtils.getReportingDate(
                          session.startTime,
                          dayEndHour: dayEnd,
                        );
                      }
                    });
                },
                onLongPress: () async {
                  if (session.id != null && session.endTime != null) {
                    final changed = await showSessionActionsSheet(
                      context,
                      ref,
                      session,
                    );
                    if (changed == true) _loadStats();
                  }
                },
                child: Container(
                  width: 75,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (data['color'] as Color).withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: data['color'] as Color, width: 1)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (data['color'] as Color).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: data['color'] as Color,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (data['color'] as Color).withValues(
                                alpha: isSelected ? 0.6 : 0.3,
                              ),
                              blurRadius: isSelected ? 15 : 8,
                              spreadRadius: isSelected ? 2 : 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          data['icon'] as IconData,
                          color: data['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${DateFormat('dd/MM').format(session.startTime)}\n${DateFormat('HH:mm').format(session.startTime)}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          shadows: AppTheme.textShadows,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              shadows: AppTheme.textShadows,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
              letterSpacing: 1,
              shadows: AppTheme.textShadows,
            ),
          ),
        ),
      ],
    );
  }
}
