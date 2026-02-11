import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import 'pdf_preview_screen.dart';
import '../../providers/timer_provider.dart';
import '../../utils/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

enum ReportViewMode { week, month }

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  Map<DateTime, int> _allStats = {};
  bool _isLoading = true;
  ReportViewMode _viewMode = ReportViewMode.week;
  DateTime _focusDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseService().getDailySummaries();
    setState(() {
      _allStats = stats;
      _isLoading = false;
    });
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

    // Dynamic scale: max of data + 15% margin, but at least 1 hour
    double chartMaxY = math.max(60.0, maxMinutes * 1.15);

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
        title: const Text("Statistiques"),
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
                        segments: const [
                          ButtonSegment(
                            value: ReportViewMode.week,
                            label: Text("Semaine"),
                            icon: Icon(Icons.view_week),
                          ),
                          ButtonSegment(
                            value: ReportViewMode.month,
                            label: Text("Mois"),
                            icon: Icon(Icons.calendar_month),
                          ),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _viewMode = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _navigate(-1),
                          ),
                          Text(
                            periodLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _navigate(1),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Summary Cards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSummaryCard(
                            "Moyenne",
                            "${(avgMinutes / 60).toStringAsFixed(1)}h",
                          ),
                          _buildSummaryCard(
                            _viewMode == ReportViewMode.week
                                ? "Total 7j"
                                : "Total Mois",
                            "${(totalMinutes / 60).toStringAsFixed(1)}h",
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Chart area with zoom support
                      Expanded(
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
                                  if (targetMins <= chartMaxY)
                                    HorizontalLine(
                                      y: targetMins.toDouble(),
                                      color: Colors.green.withValues(
                                        alpha: 0.5,
                                      ),
                                      strokeWidth: 2,
                                      dashArray: [5, 5],
                                      label: HorizontalLineLabel(
                                        show: true,
                                        alignment: Alignment.topRight,
                                        padding: const EdgeInsets.only(
                                          right: 5,
                                          bottom: 2,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        labelResolver: (line) => 'Objectif',
                                      ),
                                    ),
                                ],
                              ),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          '${(rod.toY / 60).toStringAsFixed(1)}h',
                                          const TextStyle(
                                            color: AppTheme.primaryColor,
                                          ),
                                        );
                                      },
                                ),
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

                                          final date = startOfPeriod.add(
                                            Duration(days: index),
                                          );

                                          // For Month view, don't show all titles to avoid overlap
                                          if (_viewMode ==
                                              ReportViewMode.month) {
                                            if (index % 5 != 0 &&
                                                index != daysInPeriod - 1) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                "${date.day}",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Text(
                                              DateFormat(
                                                'E',
                                                'fr_FR',
                                              ).format(date),
                                              style: const TextStyle(
                                                fontSize: 11,
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
                                    getTitlesWidget: (value, meta) {
                                      // Dynamic interval for labels
                                      double interval = 60; // 1h
                                      if (chartMaxY > 600) {
                                        interval = 240; // 4h
                                      } else if (chartMaxY > 300) {
                                        interval = 120; // 2h
                                      } else if (chartMaxY < 120) {
                                        interval = 30; // 30m
                                      }

                                      if (value % interval == 0) {
                                        if (value >= 60) {
                                          return Text(
                                            '${(value / 60).toStringAsFixed(value % 60 == 0 ? 0 : 1)}h',
                                          );
                                        } else if (value > 0) {
                                          return Text('${value.toInt()}m');
                                        }
                                        return const Text('0');
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: chartMaxY > 600 ? 120 : 60,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(daysInPeriod, (index) {
                                final date = startOfPeriod.add(
                                  Duration(days: index),
                                );
                                final normalizedDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                );

                                int minutes = _allStats[normalizedDate] ?? 0;

                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: minutes.toDouble(),
                                      color: minutes >= targetMins
                                          ? AppTheme.successColor
                                          : AppTheme.warningColor,
                                      width: _viewMode == ReportViewMode.week
                                          ? 22
                                          : 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
