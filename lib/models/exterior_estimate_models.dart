/// Interior walls vs exterior surfaces (decks, siding, fences, etc.).
enum EstimateJobKind {
  interior('Interior'),
  exterior('Exterior');

  const EstimateJobKind(this.label);
  final String label;

  static EstimateJobKind fromName(String? name) {
    return EstimateJobKind.values.firstWhere(
      (kind) => kind.name == name,
      orElse: () => EstimateJobKind.interior,
    );
  }
}

/// How an exterior measurement is entered and billed.
enum ExteriorMeasureUnit {
  squareFeet('Sq Ft', 'sq ft'),
  linearFeet('Lin Ft', 'lin ft');

  const ExteriorMeasureUnit(this.label, this.shortLabel);
  final String label;
  final String shortLabel;

  static ExteriorMeasureUnit fromName(String? name) {
    return ExteriorMeasureUnit.values.firstWhere(
      (unit) => unit.name == name,
      orElse: () => ExteriorMeasureUnit.squareFeet,
    );
  }
}

/// Finish applied to an exterior surface.
enum ExteriorFinish {
  paint(
    label: 'Paint',
    coverageSqFtPerGallon: 350,
    hint: 'Siding, trim, and previously coated exteriors',
  ),
  stain(
    label: 'Stain',
    coverageSqFtPerGallon: 200,
    hint: 'Decks, fences, and raw or weathered wood',
  );

  const ExteriorFinish({
    required this.label,
    required this.coverageSqFtPerGallon,
    required this.hint,
  });

  final String label;
  final double coverageSqFtPerGallon;
  final String hint;

  static ExteriorFinish fromName(String? name) {
    return ExteriorFinish.values.firstWhere(
      (finish) => finish.name == name,
      orElse: () => ExteriorFinish.paint,
    );
  }
}

/// One exterior surface the estimator is quoting.
class ExteriorJobLine {
  ExteriorJobLine({
    required this.id,
    this.description = '',
    this.sqFt = '',
    this.unit = ExteriorMeasureUnit.squareFeet,
    this.extraDescription = '',
    this.extraSqFt = '',
    this.extraUnit = ExteriorMeasureUnit.linearFeet,
    this.finish = ExteriorFinish.paint,
    this.coats = 2,
  });

  final String id;
  String description;
  String sqFt;
  ExteriorMeasureUnit unit;
  String extraDescription;
  String extraSqFt;
  ExteriorMeasureUnit extraUnit;
  ExteriorFinish finish;
  int coats;

  bool get isEmpty =>
      description.trim().isEmpty &&
      sqFtValue <= 0 &&
      extraDescription.trim().isEmpty &&
      extraSqFtValue <= 0;

  bool get hasExtra => extraDescription.trim().isNotEmpty || extraSqFtValue > 0;

  double get sqFtValue => double.tryParse(sqFt.trim()) ?? 0;

  double get extraSqFtValue => double.tryParse(extraSqFt.trim()) ?? 0;

  ExteriorJobLine copyWith({
    String? description,
    String? sqFt,
    ExteriorMeasureUnit? unit,
    String? extraDescription,
    String? extraSqFt,
    ExteriorMeasureUnit? extraUnit,
    ExteriorFinish? finish,
    int? coats,
  }) {
    return ExteriorJobLine(
      id: id,
      description: description ?? this.description,
      sqFt: sqFt ?? this.sqFt,
      unit: unit ?? this.unit,
      extraDescription: extraDescription ?? this.extraDescription,
      extraSqFt: extraSqFt ?? this.extraSqFt,
      extraUnit: extraUnit ?? this.extraUnit,
      finish: finish ?? this.finish,
      coats: coats ?? this.coats,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'sqFt': sqFt,
        'unit': unit.name,
        'extraDescription': extraDescription,
        'extraSqFt': extraSqFt,
        'extraUnit': extraUnit.name,
        'finish': finish.name,
        'coats': coats,
      };

  factory ExteriorJobLine.fromMap(Map<String, dynamic> map) {
    return ExteriorJobLine(
      id: map['id'] as String? ?? '0',
      description: map['description'] as String? ?? '',
      sqFt: map['sqFt'] as String? ?? '',
      unit: ExteriorMeasureUnit.fromName(map['unit'] as String?),
      extraDescription: map['extraDescription'] as String? ?? '',
      extraSqFt: map['extraSqFt'] as String? ?? '',
      extraUnit: ExteriorMeasureUnit.fromName(
        map['extraUnit'] as String? ?? ExteriorMeasureUnit.linearFeet.name,
      ),
      finish: ExteriorFinish.fromName(map['finish'] as String?),
      coats: (map['coats'] as num?)?.toInt() ?? 2,
    );
  }
}

/// Per-line math shown on the invoice and PDF.
class ExteriorLineBreakdown {
  const ExteriorLineBreakdown({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.finish,
    required this.coats,
    required this.coverageSqFtPerGallon,
    required this.rawGallons,
    required this.totalGallons,
    required this.pricePerGallon,
    required this.materialCost,
    required this.laborCost,
    required this.lineTotal,
  });

  final String id;
  final String description;
  final double quantity;
  final ExteriorMeasureUnit unit;
  final ExteriorFinish finish;
  final int coats;
  final double coverageSqFtPerGallon;
  final double rawGallons;
  final int totalGallons;
  final double pricePerGallon;
  final double materialCost;
  final double laborCost;
  final double lineTotal;

  double get sqFt => quantity;

  String get displayName {
    final name = description.trim();
    return name.isEmpty ? 'Untitled surface' : name;
  }

  String get measureLabel => '${quantity.round()} ${unit.shortLabel}';
}

/// Combined exterior estimate used by the invoice, SMS, and PDF.
class ExteriorEstimateBreakdown {
  const ExteriorEstimateBreakdown({
    required this.lines,
    required this.laborPricePerSqFt,
    required this.laborPricePerLinFt,
    required this.paintPricePerGallon,
    required this.stainPricePerGallon,
    required this.totalSqFt,
    required this.totalLinFt,
    required this.paintGallons,
    required this.stainGallons,
    required this.materialCost,
    required this.laborCost,
    required this.totalEstimate,
  });

  final List<ExteriorLineBreakdown> lines;
  final double laborPricePerSqFt;
  final double laborPricePerLinFt;
  final double paintPricePerGallon;
  final double stainPricePerGallon;
  final double totalSqFt;
  final double totalLinFt;
  final int paintGallons;
  final int stainGallons;
  final double materialCost;
  final double laborCost;
  final double totalEstimate;

  int get totalGallons => paintGallons + stainGallons;

  String get areaSummary {
    final parts = <String>[];
    if (totalSqFt > 0) parts.add('${totalSqFt.round()} sq ft');
    if (totalLinFt > 0) parts.add('${totalLinFt.round()} lin ft');
    if (parts.isEmpty) return '0 sq ft';
    return parts.join(' · ');
  }

  factory ExteriorEstimateBreakdown.calculate({
    required List<ExteriorJobLine> jobLines,
    required double laborPricePerSqFt,
    double laborPricePerLinFt = 0,
    required double paintPricePerGallon,
    required double stainPricePerGallon,
  }) {
    final linFtRate =
        laborPricePerLinFt > 0 ? laborPricePerLinFt : laborPricePerSqFt;
    final lineBreakdowns = <ExteriorLineBreakdown>[];
    var totalSqFt = 0.0;
    var totalLinFt = 0.0;
    var paintGallons = 0;
    var stainGallons = 0;
    var materialCost = 0.0;
    var laborCost = 0.0;

    void addSegment({
      required String id,
      required String description,
      required double quantity,
      required ExteriorMeasureUnit unit,
      required ExteriorFinish finish,
      required int coats,
      required String fallbackName,
    }) {
      final qty = quantity.clamp(0, double.infinity).toDouble();
      final coatCount = coats.clamp(1, 3);
      final coverage = finish.coverageSqFtPerGallon;
      final pricePerGallon = finish == ExteriorFinish.stain
          ? stainPricePerGallon
          : paintPricePerGallon;
      final laborRate = unit == ExteriorMeasureUnit.linearFeet
          ? linFtRate
          : laborPricePerSqFt;

      final rawGallons = coatCount > 0 && qty > 0 && coverage > 0
          ? (qty * coatCount) / coverage
          : 0.0;
      final gallons = rawGallons.ceil();
      final lineMaterial = gallons * pricePerGallon;
      final lineLabor = qty * laborRate;
      final lineTotal = lineMaterial + lineLabor;
      final name = description.trim().isEmpty ? fallbackName : description;

      lineBreakdowns.add(
        ExteriorLineBreakdown(
          id: id,
          description: name,
          quantity: qty,
          unit: unit,
          finish: finish,
          coats: coatCount,
          coverageSqFtPerGallon: coverage,
          rawGallons: rawGallons,
          totalGallons: gallons,
          pricePerGallon: pricePerGallon,
          materialCost: lineMaterial,
          laborCost: lineLabor,
          lineTotal: lineTotal,
        ),
      );

      if (unit == ExteriorMeasureUnit.linearFeet) {
        totalLinFt += qty;
      } else {
        totalSqFt += qty;
      }
      materialCost += lineMaterial;
      laborCost += lineLabor;
      if (finish == ExteriorFinish.stain) {
        stainGallons += gallons;
      } else {
        paintGallons += gallons;
      }
    }

    for (final line in jobLines) {
      final mainEmpty =
          line.description.trim().isEmpty && line.sqFtValue <= 0;
      if (!mainEmpty || !line.hasExtra) {
        addSegment(
          id: line.id,
          description: line.description,
          quantity: line.sqFtValue,
          unit: line.unit,
          finish: line.finish,
          coats: line.coats,
          fallbackName: 'Untitled surface',
        );
      }
      if (line.hasExtra) {
        addSegment(
          id: '${line.id}-extra',
          description: line.extraDescription,
          quantity: line.extraSqFtValue,
          unit: line.extraUnit,
          finish: line.finish,
          coats: line.coats,
          fallbackName: 'Railings / spindles',
        );
      }
    }

    return ExteriorEstimateBreakdown(
      lines: lineBreakdowns,
      laborPricePerSqFt: laborPricePerSqFt,
      laborPricePerLinFt: linFtRate,
      paintPricePerGallon: paintPricePerGallon,
      stainPricePerGallon: stainPricePerGallon,
      totalSqFt: totalSqFt,
      totalLinFt: totalLinFt,
      paintGallons: paintGallons,
      stainGallons: stainGallons,
      materialCost: materialCost,
      laborCost: laborCost,
      totalEstimate: materialCost + laborCost,
    );
  }
}
