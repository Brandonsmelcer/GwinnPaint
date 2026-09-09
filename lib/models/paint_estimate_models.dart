/// Supported paint manufacturers for color log entries.
enum PaintBrand {
  sherwinWilliams('Sherwin-Williams'),
  benjaminMoore('Benjamin Moore'),
  behr('Behr'),
  custom('Custom');

  const PaintBrand(this.label);
  final String label;
}

/// A single room/color specification logged by the estimator.
class ColorLog {
  ColorLog({
    required this.id,
    this.roomName = '',
    this.brand = PaintBrand.sherwinWilliams,
    this.colorName = '',
  });

  final String id;
  String roomName;
  PaintBrand brand;
  String colorName;

  bool get isEmpty => roomName.trim().isEmpty && colorName.trim().isEmpty;

  ColorLog copyWith({
    String? roomName,
    PaintBrand? brand,
    String? colorName,
  }) {
    return ColorLog(
      id: id,
      roomName: roomName ?? this.roomName,
      brand: brand ?? this.brand,
      colorName: colorName ?? this.colorName,
    );
  }
}

/// Derived estimate values recomputed on every input change.
class EstimateBreakdown {
  const EstimateBreakdown({
    required this.totalSqFt,
    required this.doors,
    required this.windows,
    required this.includeDoorsWindows,
    required this.coats,
    required this.netSqFt,
    required this.rawGallons,
    required this.totalGallons,
    required this.pricePerGallon,
    required this.materialCost,
    required this.laborCost,
    required this.totalEstimate,
  });

  final double totalSqFt;
  final int doors;
  final int windows;

  /// When false, door/window counts are ignored in math and client exports.
  final bool includeDoorsWindows;
  final int coats;
  final double netSqFt;
  final double rawGallons;
  final int totalGallons;
  final double pricePerGallon;
  final double materialCost;
  final double laborCost;
  final double totalEstimate;

  factory EstimateBreakdown.calculate({
    required double totalSqFt,
    required double pricePerSqFt,
    required int coats,
    required int doors,
    required int windows,
    required double pricePerGallon,
    bool includeDoorsWindows = false,
  }) {
    final effectiveDoors = includeDoorsWindows ? doors : 0;
    final effectiveWindows = includeDoorsWindows ? windows : 0;

    // Net paintable area after optional door/window deductions.
    final netSqFt =
        (totalSqFt - (effectiveDoors * 20) - (effectiveWindows * 15)).clamp(0, double.infinity);

    // Industry rule-of-thumb: ~350 sq ft coverage per gallon per coat.
    final rawGallons = coats > 0 && netSqFt > 0 ? (netSqFt * coats) / 350 : 0.0;
    final totalGallons = rawGallons.ceil();

    final materialCost = totalGallons * pricePerGallon;
    final laborCost = netSqFt * pricePerSqFt;
    final totalEstimate = materialCost + laborCost;

    return EstimateBreakdown(
      totalSqFt: totalSqFt,
      doors: effectiveDoors,
      windows: effectiveWindows,
      includeDoorsWindows: includeDoorsWindows,
      coats: coats,
      netSqFt: netSqFt.toDouble(),
      rawGallons: rawGallons,
      totalGallons: totalGallons,
      pricePerGallon: pricePerGallon,
      materialCost: materialCost,
      laborCost: laborCost,
      totalEstimate: totalEstimate,
    );
  }
}
