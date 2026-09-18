import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_strings.dart';
import '../services/cycle_predictor.dart';

DateTime _parseKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Genera el mismo reporte en PDF que `exportPdfReport()` del prototipo
/// (resumen + historial de ciclos), usando los paquetes `pdf` y
/// `printing` en vez de jsPDF. `printing` se encarga de mostrar el diálogo
/// nativo de compartir/guardar/imprimir.
class PdfReportService {
  Future<void> exportAndShare(CyclePredictor predictor, AppStrings s) async {
    final cycles = predictor.getCycles();
    final avgCycle = predictor.getAvgCycleLength();
    final avgPeriod = predictor.getAvgPeriodLength();

    String dayLabel(DateTime d) => s.dayLabel(d.day, d.month);

    final doc = pw.Document();
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(s.pdfReportHeader, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(s.pdfGeneratedOn('${now.day}/${now.month}/${now.year}'), style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 18),
          pw.Text(s.pdfSummaryTitle, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(s.pdfCyclesLogged(cycles.length), style: const pw.TextStyle(fontSize: 10)),
          pw.Text(s.pdfAvgCycleLength(avgCycle), style: const pw.TextStyle(fontSize: 10)),
          pw.Text(s.pdfAvgPeriodLength(avgPeriod), style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 18),
          pw.Text(s.pdfCycleHistoryTitle, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          ...cycles.reversed.take(15).map((cycle) {
            final start = _parseKey(cycle.first);
            final end = _parseKey(cycle.last);
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '${dayLabel(start)} – ${dayLabel(end)} (${s.pdfCycleDaysCount(cycle.length)})',
                style: const pw.TextStyle(fontSize: 10),
              ),
            );
          }),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: s.pdfFilename);
  }
}
