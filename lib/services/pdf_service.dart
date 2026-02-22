import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../utils/app_defaults.dart';
import 'database_service.dart';

/// Service gérant la génération de rapports au format PDF avec graphiques.
class PdfService {
  /// Construit le document PDF avec un graphique à barres et un tableau de données.
  Future<pw.Document> buildDocument(
    Map<DateTime, int> stats,
    String periodLabel,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(now);

    final goalStr = await DatabaseService().getSetting('daily_goal');
    final goalHours = int.tryParse(goalStr ?? '') ?? AppDefaults.dailyGoalHours;

    // Calculate Summary Stats
    int totalMinutes = stats.values.fold(0, (sum, val) => sum + val);
    int maxMinutes = stats.values.isEmpty ? 0 : stats.values.reduce(math.max);

    // Max Y is the highest between actual data and goal, plus 1 hour
    int chartMaxY = math.max(goalHours, (maxMinutes / 60).toInt()) + 1;

    double avgMinutes = stats.isEmpty
        ? 0
        : totalMinutes / (stats.isNotEmpty ? stats.length : 1);
    String avgStr = "${(avgMinutes / 60).toStringAsFixed(1)}h";
    String totalStr = "${(totalMinutes / 60).toStringAsFixed(1)}h";

    // Sort stats by date ascending for the chart
    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Fetch sessions for detailed table
    final allSessions = await DatabaseService().getSessions();
    final sortedEntriesDates = sortedEntries
        .map((e) => DateTime(e.key.year, e.key.month, e.key.day))
        .toList();

    final periodSessions = allSessions.where((s) {
      if (s.endTime == null) return false;
      final sessionDate = DateTime(
        s.startTime.year,
        s.startTime.month,
        s.startTime.day,
      );
      return sortedEntriesDates.any((d) => d.isAtSameMomentAs(sessionDate));
    }).toList();

    periodSessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    final isLandscape = sortedEntries.length > 7;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(
          35,
        ), // Reduce margins slightly to gain space
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Rapport OrthoQuest",
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.Text(
                        periodLabel,
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey800,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    dateStr,
                    style: const pw.TextStyle(color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard("Moyenne / Jour", avgStr),
                _buildSummaryCard("Total Période", totalStr),
                _buildSummaryCard("Objectif", "${goalHours}h"),
              ],
            ),
            pw.SizedBox(height: 20),

            // CHART SECTION
            pw.Text(
              "Évolution du temps de port",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            if (sortedEntries.isNotEmpty)
              pw.Container(
                height: isLandscape ? 320 : 300,
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis(
                      List.generate(sortedEntries.length, (i) => i.toDouble()),
                      format: (v) => DateFormat(
                        'dd/MM',
                      ).format(sortedEntries[v.toInt()].key),
                      angle: -math.pi / 2,
                    ),
                    yAxis: pw.FixedAxis(
                      List.generate(
                        (chartMaxY + 1), // De 0 à chartMaxY
                        (i) => i.toDouble(),
                      ),
                      format: (v) => "${v.toInt()}h",
                    ),
                  ),
                  datasets: [
                    pw.BarDataSet(
                      color: PdfColors.blue,
                      width: sortedEntries.length > 7 ? 15 : 30,
                      data: List<pw.PointChartValue>.generate(
                        sortedEntries.length,
                        (i) {
                          final v = sortedEntries[i].value.toDouble() / 60;
                          return pw.PointChartValue(i.toDouble(), v);
                        },
                      ),
                    ),
                    if (sortedEntries.isNotEmpty)
                      pw.LineDataSet(
                        color: PdfColors.green,
                        drawPoints: false,
                        lineWidth: 2,
                        data: [
                          pw.PointChartValue(0, goalHours.toDouble()),
                          pw.PointChartValue(
                            (sortedEntries.length - 1).toDouble(),
                            goalHours.toDouble(),
                          ),
                        ],
                      ),
                  ],
                ),
              )
            else
              pw.Center(child: pw.Text("Aucune donnée pour cette période")),

            if (isLandscape)
              pw.NewPage(), // Nouvelle page seulement pour le mode paysage (mensuel)
            if (!isLandscape) pw.SizedBox(height: 20),
            // DATA TABLE
            pw.Text(
              "Détail des sessions",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ["Date", "Début", "Fin", "Durée", "Sticker"],
              data: periodSessions.map((s) {
                final date = DateFormat('dd/MM/yyyy').format(s.startTime);
                final start = DateFormat('HH:mm').format(s.startTime);
                final end = DateFormat('HH:mm').format(s.endTime!);
                final diff = s.endTime!.difference(s.startTime);
                final duration = "${diff.inHours}h ${diff.inMinutes % 60}min";

                String stickerName = "Standard";
                if (s.stickerId != null) {
                  stickerName = s.stickerId.toString();
                }

                return [date, start, end, duration, stickerName];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
            ),

            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 30),
              child: pw.Center(
                child: pw.Text(
                  "Félicitations pour tes progrès ! Continue comme ça.",
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  /// Génère un rapport PDF et lance le partage direct.
  Future<void> generateReport(
    Map<DateTime, int> stats,
    String periodLabel,
  ) async {
    final pdf = await buildDocument(stats, periodLabel);
    final now = DateTime.now();
    final fileDateStr = DateFormat('dd-MM-yyyy').format(now);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'rapport_orthoquest_$fileDateStr.pdf',
    );
  }

  pw.Widget _buildSummaryCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue800),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ],
      ),
    );
  }
}
