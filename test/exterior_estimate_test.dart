import 'package:flutter_test/flutter_test.dart';

import 'package:paint_estimate_calculator/models/exterior_estimate_models.dart';
import 'package:paint_estimate_calculator/services/estimate_export_service.dart';

void main() {
  group('ExteriorEstimateBreakdown', () {
    test('stain uses 200 sq ft coverage and rounds gallons up', () {
      final breakdown = ExteriorEstimateBreakdown.calculate(
        jobLines: [
          ExteriorJobLine(
            id: '1',
            description: 'Front deck',
            sqFt: '400',
            finish: ExteriorFinish.stain,
            coats: 2,
          ),
        ],
        laborPricePerSqFt: 3,
        paintPricePerGallon: 45,
        stainPricePerGallon: 55,
      );

      expect(breakdown.totalSqFt, 400);
      expect(breakdown.stainGallons, 4); // (400 * 2) / 200 = 4
      expect(breakdown.paintGallons, 0);
      expect(breakdown.materialCost, 220); // 4 * 55
      expect(breakdown.laborCost, 1200); // 400 * 3
      expect(breakdown.totalEstimate, 1420);
      expect(breakdown.lines.single.displayName, 'Front deck');
    });

    test('paint uses 350 sq ft coverage', () {
      final breakdown = ExteriorEstimateBreakdown.calculate(
        jobLines: [
          ExteriorJobLine(
            id: '1',
            description: 'House siding',
            sqFt: '700',
            finish: ExteriorFinish.paint,
            coats: 1,
          ),
        ],
        laborPricePerSqFt: 2,
        paintPricePerGallon: 45,
        stainPricePerGallon: 55,
      );

      expect(breakdown.paintGallons, 2); // (700 * 1) / 350 = 2
      expect(breakdown.stainGallons, 0);
      expect(breakdown.materialCost, 90);
      expect(breakdown.laborCost, 1400);
    });

    test('combines paint and stain surfaces on one estimate', () {
      final breakdown = ExteriorEstimateBreakdown.calculate(
        jobLines: [
          ExteriorJobLine(
            id: '1',
            description: 'Front deck',
            sqFt: '200',
            finish: ExteriorFinish.stain,
            coats: 2,
          ),
          ExteriorJobLine(
            id: '2',
            description: 'Siding',
            sqFt: '350',
            finish: ExteriorFinish.paint,
            coats: 2,
          ),
        ],
        laborPricePerSqFt: 2.5,
        paintPricePerGallon: 45,
        stainPricePerGallon: 50,
      );

      expect(breakdown.stainGallons, 2); // 400 / 200
      expect(breakdown.paintGallons, 2); // 700 / 350
      expect(breakdown.totalSqFt, 550);
      expect(breakdown.materialCost, 190); // 2*50 + 2*45
    });

    test('empty description falls back to untitled surface', () {
      final breakdown = ExteriorEstimateBreakdown.calculate(
        jobLines: [ExteriorJobLine(id: '1', sqFt: '10')],
        laborPricePerSqFt: 1,
        paintPricePerGallon: 45,
        stainPricePerGallon: 55,
      );
      expect(breakdown.lines.single.displayName, 'Untitled surface');
    });

    test('extra railings line uses linear feet and its own labor rate', () {
      final breakdown = ExteriorEstimateBreakdown.calculate(
        jobLines: [
          ExteriorJobLine(
            id: '1',
            description: 'Front deck',
            sqFt: '400',
            extraDescription: 'Spindles',
            extraSqFt: '40',
            extraUnit: ExteriorMeasureUnit.linearFeet,
            finish: ExteriorFinish.stain,
            coats: 2,
          ),
        ],
        laborPricePerSqFt: 3,
        laborPricePerLinFt: 6,
        paintPricePerGallon: 45,
        stainPricePerGallon: 55,
      );

      expect(breakdown.lines, hasLength(2));
      expect(breakdown.totalSqFt, 400);
      expect(breakdown.totalLinFt, 40);
      expect(breakdown.areaSummary, '400 sq ft · 40 lin ft');
      expect(breakdown.stainGallons, 5); // 4 from deck + ceil(80/200)=1
      expect(breakdown.laborCost, 1440); // 400*3 + 40*6
      expect(breakdown.lines.last.displayName, 'Spindles');
      expect(breakdown.lines.last.measureLabel, '40 lin ft');
    });
  });

  test('exterior text estimate includes job name, stain, and total', () {
    final breakdown = ExteriorEstimateBreakdown.calculate(
      jobLines: [
        ExteriorJobLine(
          id: '1',
          description: 'Back deck',
          sqFt: '200',
          finish: ExteriorFinish.stain,
          coats: 2,
        ),
      ],
      laborPricePerSqFt: 2,
      paintPricePerGallon: 45,
      stainPricePerGallon: 55,
    );

    final text = EstimateExportService.buildExteriorTextEstimate(breakdown);
    expect(text, contains('EXTERIOR ESTIMATE'));
    expect(text, contains('Back deck'));
    expect(text, contains('Stain'));
    expect(text, contains('200 sq ft'));
    expect(text, contains('Total Investment'));
  });
}
