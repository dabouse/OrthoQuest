import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
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

    // Fetch dynamic goal
    final goalStr = await DatabaseService().getSetting('daily_goal');
    final goalHours = int.tryParse(goalStr ?? '13') ?? 13;
    final targetMinutes = goalHours * 60;

    // Calculate Summary Stats
    int totalMinutes = stats.values.fold(0, (sum, val) => sum + val);
    double avgMinutes = stats.isEmpty
        ? 0
        : totalMinutes / (stats.isNotEmpty ? stats.length : 1);
    String avgStr = "${(avgMinutes / 60).toStringAsFixed(1)}h";
    String totalStr = "${(totalMinutes / 60).toStringAsFixed(1)}h";

    // Sort stats by date ascending for the chart
    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Sort descending for the table
    final tableEntries = List.from(sortedEntries.reversed);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: sortedEntries.length > 7
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4,
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
            pw.SizedBox(height: 30),

            // CHART SECTION
            pw.Text(
              "Évolution du temps de port",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            if (sortedEntries.isNotEmpty)
              pw.Container(
                height: 300, // Slightly taller in landscape
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis(
                      List.generate(sortedEntries.length, (i) => i.toDouble()),
                      format: (v) => DateFormat(
                        'dd/MM',
                      ).format(sortedEntries[v.toInt()].key),
                      angle: -math.pi / 2,
                    ),
                    yAxis: pw.FixedAxis([
                      0,
                      4,
                      8,
                      12,
                      16,
                      20,
                      24,
                    ], format: (v) => "${v.toInt()}h"),
                  ),
                  datasets: [
                    pw.BarDataSet(
                      color: PdfColors.blue,
                      width: sortedEntries.length > 7
                          ? 15
                          : 30, // Wider bars allowed in landscape
                      data: List<pw.PointChartValue>.generate(
                        sortedEntries.length,
                        (i) {
                          final v = sortedEntries[i].value.toDouble() / 60;
                          return pw.PointChartValue(i.toDouble(), v);
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              pw.Center(child: pw.Text("Aucune donnée pour cette période")),

            pw.SizedBox(height: 40),

            // DATA TABLE
            pw.Text(
              "Détail des sessions",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ["Date", "Temps de port", "Objectif (${goalHours}h)"],
              data: tableEntries.map((e) {
                final date = DateFormat('dd/MM/yyyy').format(e.key);
                final duration = "${(e.value / 60).toStringAsFixed(1)}h";
                final goalMet = e.value >= targetMinutes
                    ? "Atteint"
                    : "Insuffisant";
                return [date, duration, goalMet];
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
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
              },
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
