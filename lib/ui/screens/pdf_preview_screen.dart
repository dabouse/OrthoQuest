import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../services/pdf_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Map<DateTime, int> stats;
  final String periodLabel;

  const PdfPreviewScreen({
    super.key,
    required this.stats,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aperçu du rapport")),
      body: PdfPreview(
        build: (format) async {
          final pdf = await PdfService().buildDocument(stats, periodLabel);
          return pdf.save();
        },
        allowPrinting: true,
        allowSharing: true,
        initialPageFormat: const PdfPageFormat(
          21.0 * PdfPageFormat.cm,
          29.7 * PdfPageFormat.cm,
        ),
        canDebug: false,
        pdfFileName: "rapport_orthoquest.pdf",
      ),
    );
  }
}
