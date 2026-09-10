import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/exterior_estimate_models.dart';
import '../theme/paint_estimate_theme.dart';

/// Live exterior invoice with send and download actions.
class ExteriorInvoicePanel extends StatelessWidget {
  const ExteriorInvoicePanel({
    super.key,
    required this.breakdown,
    required this.onSendEstimate,
    required this.onDownloadPdf,
    required this.onTextEstimate,
  });

  final ExteriorEstimateBreakdown breakdown;
  final VoidCallback onSendEstimate;
  final VoidCallback onDownloadPdf;
  final VoidCallback onTextEstimate;

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final visibleLines = breakdown.lines
        .where((line) => line.quantity > 0 || line.description.trim().isNotEmpty)
        .toList();

    return Container(
      decoration: PaintEstimateTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: PaintEstimateTheme.navyHeaderDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXTERIOR ESTIMATE',
                        style: PaintEstimateTheme.titleStyle(
                          size: 16,
                          color: PaintEstimateTheme.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Decks, siding, fences · live preview',
                        style: PaintEstimateTheme.bodyStyle(
                          size: 12,
                          color: PaintEstimateTheme.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: PaintEstimateTheme.warmGold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DRAFT',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: PaintEstimateTheme.midnightNavy,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionTitle('Surfaces'),
                if (visibleLines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Add a surface name and footage to build this estimate.',
                      style: PaintEstimateTheme.bodyStyle(
                        color: PaintEstimateTheme.charcoal.withValues(alpha: 0.65),
                      ),
                    ),
                  )
                else
                  ...visibleLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SurfaceInvoiceItem(line: line, money: _money),
                    ),
                  ),
                const SizedBox(height: 8),
                const _SectionTitle('Totals'),
                _Row(
                  label: 'Total Area',
                  value: breakdown.areaSummary,
                  emphasized: true,
                ),
                _Row(
                  label: 'Paint Required',
                  value: '${breakdown.paintGallons} gal',
                ),
                _Row(
                  label: 'Stain Required',
                  value: '${breakdown.stainGallons} gal',
                ),
                _Row(
                  label: 'Material',
                  value: _money(breakdown.materialCost),
                ),
                _Row(
                  label: 'Labor',
                  value: _money(breakdown.laborCost),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: PaintEstimateTheme.warmGold.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                _Row(
                  label: 'TOTAL ESTIMATE',
                  value: _money(breakdown.totalEstimate),
                  isTotal: true,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: onSendEstimate,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Send Estimate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PaintEstimateTheme.warmGold,
                    foregroundColor: PaintEstimateTheme.midnightNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTextEstimate,
                        icon: const Icon(Icons.sms_outlined, size: 18),
                        label: const Text('Text'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDownloadPdf,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Download PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PaintEstimateTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Paint coverage ~350 sq ft per gallon per coat. '
              'Stain coverage ~200 sq ft per gallon per coat for decks and raw wood. '
              'Adjust gallons on site if the surface is extra porous.',
              style: PaintEstimateTheme.bodyStyle(
                size: 11,
                color: PaintEstimateTheme.charcoal.withValues(alpha: 0.78),
              ).copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceInvoiceItem extends StatelessWidget {
  const _SurfaceInvoiceItem({required this.line, required this.money});

  final ExteriorLineBreakdown line;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final coatsLabel = line.coats == 1 ? '1 coat' : '${line.coats} coats';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PaintEstimateTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: PaintEstimateTheme.warmGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.displayName,
                  style: PaintEstimateTheme.bodyStyle(weight: FontWeight.w700),
                ),
              ),
              Text(
                money(line.lineTotal),
                style: PaintEstimateTheme.monoStyle(
                  size: 13,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              '${line.measureLabel} · ${line.finish.label} · $coatsLabel · '
              '${line.totalGallons} gal',
              style: PaintEstimateTheme.monoStyle(
                size: 11,
                color: PaintEstimateTheme.charcoal.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: PaintEstimateTheme.warmGold,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: PaintEstimateTheme.bodyStyle(
                size: isTotal ? 15 : 13,
                weight: isTotal || emphasized ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: PaintEstimateTheme.monoStyle(
              size: isTotal ? 20 : emphasized ? 14 : 13,
              weight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal ? PaintEstimateTheme.warmGold : PaintEstimateTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}
