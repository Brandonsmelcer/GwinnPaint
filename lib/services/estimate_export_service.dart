import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/paint_estimate_models.dart';

/// Builds plain-text and PDF exports for client-facing estimates.
abstract final class EstimateExportService {
  static const _divider = '--------------------------------------------';

  /// Plain-text template for SMS / WhatsApp sharing.
  static String buildTextEstimate(EstimateBreakdown breakdown) {
    final netArea = breakdown.netSqFt.round();
    final coatsLabel = breakdown.coats == 1 ? '1 Coat' : '${breakdown.coats} Coats';
    final total = breakdown.totalEstimate.toStringAsFixed(2);

    return '''
$_divider
GWINN PAINTING SOLUTIONS - ESTIMATE
$_divider
Project Net Area: $netArea sq ft
Total Paint Needed: ${breakdown.totalGallons} Gallons ($coatsLabel)

Total Investment: \$$total
$_divider
*Reply to this message to lock in your booking date.*''';
  }

  /// Copies text to clipboard and opens the native share sheet when available.
  static Future<void> shareTextEstimate(EstimateBreakdown breakdown) async {
    final text = buildTextEstimate(breakdown);
    await Clipboard.setData(ClipboardData(text: text));
    await Share.share(text, subject: 'Gwinn Painting Solutions - Estimate');
  }

  /// Generates and opens the system print / save-as-PDF dialog.
  static Future<void> downloadPdfProposal({
    required EstimateBreakdown breakdown,
    required List<ColorLog> colorLogs,
  }) async {
    final doc = await _buildPdfDocument(breakdown, colorLogs);
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'Gwinn_Painting_Estimate.pdf',
    );
  }

  static Future<pw.Document> _buildPdfDocument(
    EstimateBreakdown breakdown,
    List<ColorLog> colorLogs,
  ) async {
    const navy = PdfColor.fromInt(0xFF0D2534);
    const gold = PdfColor.fromInt(0xFFD4AF67);
    const charcoal = PdfColor.fromInt(0xFF1E262C);
    const lightGray = PdfColor.fromInt(0xFFF4F6F9);

    final fontRegular = await PdfGoogleFonts.plusJakartaSansRegular();
    final fontBold = await PdfGoogleFonts.plusJakartaSansBold();
    final fontMono = await PdfGoogleFonts.spaceMonoRegular();

    pw.Widget sectionTitle(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6, top: 14),
          child: pw.Text(
            text.toUpperCase(),
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 9,
              letterSpacing: 1.2,
              color: gold,
            ),
          ),
        );

    pw.Widget row(String label, String value, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  label,
                  style: pw.TextStyle(
                    font: bold ? fontBold : fontRegular,
                    fontSize: 10,
                    color: charcoal,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                value,
                style: pw.TextStyle(
                  font: bold ? fontBold : fontMono,
                  fontSize: bold ? 11 : 10,
                  color: charcoal,
                ),
              ),
            ],
          ),
        );

    final colorLogWidgets = colorLogs.map((log) {
      final room = log.roomName.trim().isEmpty ? 'Unnamed Room' : log.roomName.trim();
      final color = log.colorName.trim().isEmpty ? '—' : log.colorName.trim();
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 6),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: lightGray,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          children: [
            pw.Container(width: 4, height: 4, color: gold),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(room, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                  pw.Text(
                    '$color · ${log.brand.label}',
                    style: pw.TextStyle(font: fontMono, fontSize: 9, color: charcoal),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Brand header band
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const pw.BoxDecoration(
                color: navy,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GWINN',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 22,
                      letterSpacing: 4,
                      color: gold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Container(width: 48, height: 1, color: gold),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'PAINTING SOLUTIONS',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 9,
                      letterSpacing: 2.5,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'PROFESSIONAL PAINT ESTIMATE',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 11,
                      color: PdfColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            sectionTitle('Area Calculation'),
            row('Total Wall Area', '${breakdown.totalSqFt.round()} sq ft'),
            if (breakdown.includeDoorsWindows) ...[
              row('Door Deductions (${breakdown.doors} × 20)', '−${breakdown.doors * 20} sq ft'),
              row(
                'Window Deductions (${breakdown.windows} × 15)',
                '−${breakdown.windows * 15} sq ft',
              ),
            ],
            row('Net Paintable Area', '${breakdown.netSqFt.round()} sq ft', bold: true),

            sectionTitle('Material'),
            row('Coats Applied', '${breakdown.coats}'),
            row('Gallons Required', '${breakdown.totalGallons} gal', bold: true),
            row(
              'Material Cost',
              '\$${breakdown.materialCost.toStringAsFixed(2)}',
            ),

            sectionTitle('Labor'),
            row('Labor Cost', '\$${breakdown.laborCost.toStringAsFixed(2)}'),

            if (colorLogWidgets.isNotEmpty) ...[
              sectionTitle('Color Selection'),
              ...colorLogWidgets,
            ],

            pw.Spacer(),

            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: gold, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL INVESTMENT',
                    style: pw.TextStyle(font: fontBold, fontSize: 13, color: navy),
                  ),
                  pw.Text(
                    '\$${breakdown.totalEstimate.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: gold,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),
            pw.Text(
              'Thank you for considering Gwinn Painting Solutions. '
              'Reply to confirm your booking date.',
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 9,
                color: charcoal,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Disclaimer: Digital color approximations vary. Verify selections '
              'with physical manufacturer swatches under site lighting before ordering.',
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 8,
                color: charcoal,
              ),
            ),
          ],
        ),
      ),
    );

    return doc;
  }
}
